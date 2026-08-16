require 'fileutils'

# Sequential batch downloader. The scheduler calls Downstream.process_one every
# 10 minutes; each call downloads a single movie (oldest requested first, new
# requests ahead of failed retries). Because process_one runs synchronously in a
# single background thread, only one download can ever be in flight.
class Downstream
  # Units matched in the downloader's progress log (aria2c and youtube-dl both
  # print "<done>MiB/<total>GiB(<pct>%)" lines). Values are read back to bytes.
  UNIT_BYTES = { 'B' => 1, 'KiB' => 1024, 'MiB' => 1024**2, 'GiB' => 1024**3, 'TiB' => 1024**4 }.freeze
  # aria2c lines also carry the current rate and time left, e.g.
  # "[#3f9afb 162MiB/1.0GiB(14%) CN:16 DL:396KiB ETA:40m2s]". Both the DL and
  # ETA parts are optional (youtube-dl's fallback output has neither).
  # rubocop:disable Layout/LineLength
  PROGRESS_RE = %r{(\d+(?:\.\d+)?) ?(B|KiB|MiB|GiB|TiB)/(\d+(?:\.\d+)?) ?(B|KiB|MiB|GiB|TiB) ?\((\d+)%\)(?: ?CN:\d+ DL:(\d+(?:\.\d+)?) ?(B|KiB|MiB|GiB|TiB))?(?: ?ETA:([A-Za-z0-9]+))?}
  # rubocop:enable Layout/LineLength

  # A download legitimately takes up to ~6h on the throttled CDN; anything
  # marked started longer ago than this is a crashed run, so it is freed for
  # retry (as a failed download, ordered behind new requests).
  STALE_DOWNLOAD_WINDOW = 6.hours

  # Downloads one movie per sweep: the oldest new request first, then failed
  # retries. Returns nil when the queue is empty, :done on success, and re-marks
  # the movie failed (for a later retry) when the download raises.
  def self.process_one
    clear_stale_downloads

    movie = pending.first
    unless movie
      App.logger.info('downstream: nothing to download')
      return nil
    end

    App.logger.info("downstream: downloading movie #{movie.id}")
    movie.update!(download_started_at: Time.current, download_failed_at: nil)
    result = new(movie).run
    App.logger.info("downstream: movie #{movie.id} #{result}")
    result
  rescue StandardError => e
    movie&.update!(download_started_at: nil, download_failed_at: Time.current)
    App.logger.error("downstream: movie #{movie&.id} failed: #{e.full_message}")
    nil
  end

  # New requests ahead of failed retries, oldest request first within each group.
  def self.pending
    new_requests = Movie.where(video_file_name: nil, download_started_at: nil)
                        .where.not(requested_at: nil)
                        .where(download_failed_at: nil)
                        .order(:requested_at)
    failed_retries = Movie.where(video_file_name: nil, download_started_at: nil)
                          .where.not(requested_at: nil)
                          .where.not(download_failed_at: nil)
                          .order(:requested_at)
    new_requests + failed_retries
  end

  def self.clear_stale_downloads
    Movie.where.not(download_started_at: nil)
         .where(download_started_at: ..(Time.current - STALE_DOWNLOAD_WINDOW))
         .update_all(download_started_at: nil, download_failed_at: Time.current)
  end

  def self.download_path(movie)
    App::ROOT.join('tmp', 'downloads', "movie_#{movie.id}.mp4").to_s
  end

  def self.progress_path(movie)
    "#{download_path(movie)}.log"
  end

  # "40m2s" / "2h16s" / "1m" / "0s" -> seconds; nil for "Unk" or anything else.
  def self.parse_eta(raw)
    return nil if raw.nil?

    m = raw.match(/\A(?:(?<h>\d+)h)?(?:(?<m>\d+)m)?(?:(?<s>\d+)s)?\z/)
    return nil if m.nil? || (m[:h].nil? && m[:m].nil? && m[:s].nil?)

    (m[:h].to_i * 3600) + (m[:m].to_i * 60) + m[:s].to_i
  end

  def self.rate_to_bytes(value, unit)
    return nil if value.nil? || unit.nil?

    (value.to_f * UNIT_BYTES.fetch(unit)).to_i
  end

  # Reads the latest "<done>/<total>(<pct>%)" progress line from the downloader's
  # log and returns bytes for the UI. Returns nil when there is no log or the
  # line cannot be parsed, so the status endpoint never blows up on a torn read.
  def self.download_progress(movie)
    path = progress_path(movie)
    return nil unless File.exist?(path)

    line = File.readlines(path, chomp: true).reverse.find { |l| l.match?(PROGRESS_RE) }
    return nil unless line

    m = line.match(PROGRESS_RE)
    {
      downloaded: (m[1].to_f * UNIT_BYTES.fetch(m[2])).to_i,
      total: (m[3].to_f * UNIT_BYTES.fetch(m[4])).to_i,
      percent: m[5].to_i,
      dl_bytes_per_sec: rate_to_bytes(m[6], m[7]),
      eta_seconds: parse_eta(m[8])
    }
  rescue StandardError
    nil
  end

  def initialize(movie)
    @movie = movie
  end

  def run
    return :skipped if @movie.video_attached?

    make_storage_space
    cleanup_stale_partials
    download
    attach
    :done
  end

  private

  # Removes leftover partial/control files from earlier (possibly crashed) runs.
  # A bare movie_<id>.mp4 is left alone: it cannot be a partial (aria2c and
  # youtube-dl always leave a .aria2/.part alongside an in-progress file), and
  # download reuses a complete leftover instead of re-downloading it.
  def cleanup_stale_partials
    downloads_dir = App::ROOT.join('tmp', 'downloads')
    Dir.glob(downloads_dir.join('movie_*.mp4.{part,aria2,log}')).each do |path|
      FileUtils.rm_f(path)
    end
  end

  def make_storage_space
    return unless system("[ $(df / | tail -1 | awk '{print $5}' | sed 's/%//') -ge 80 ]")

    Movie.where.not(id: @movie.id)
         .where.not(video_file_name: nil)
         .order(video_attached_at: :asc)
         .limit(3)
         .each(&:purge_video)
  end

  # The einthusan CDN throttles per-connection (single-connection downloads
  # crawl at ~10-25 KiB/s). When aria2c is available we fan out with 16 parallel
  # connections and min split 1M, which measured ~2.3 MB/s aggregate and gets a
  # 1.1 GiB movie done inside the 6h signed-URL TTL. Falls back to the plain
  # youtube-dl command when aria2c is not installed.
  def download
    return if File.exist?(download_path)

    # Capture the downloader's output so download_progress can parse byte
    # progress for the UI. Redirecting (not a tty) makes aria2c/youtube-dl
    # print newline-separated "<done>/<total>(<pct>%)" progress lines.
    progress_log = self.class.progress_path(@movie)
    success = if system('command -v aria2c >/dev/null 2>&1')
                system("#{youtube_dl_path} -o '#{download_path}' " \
                       '--external-downloader aria2c ' \
                       "--external-downloader-args '-x 16 -s 16 -k 1M " \
                       "--summary-interval=5' '#{@movie.einthusan_url}' " \
                       "> '#{progress_log}' 2>&1")
              else
                system("#{youtube_dl_path} -o '#{download_path}' '#{@movie.einthusan_url}' " \
                       "> '#{progress_log}' 2>&1")
              end
    raise "youtube-dl failed for movie #{@movie.id}" unless success || File.exist?(download_path)
  end

  def attach
    @movie.attach_video_file(download_path, content_type: 'video/mp4')
  end

  def download_path
    self.class.download_path(@movie)
  end

  def youtube_dl_path
    ENV.fetch('YOUTUBE_DL_PATH', App::ROOT.join('venv', 'bin', 'youtube-dl').to_s)
  end
end
