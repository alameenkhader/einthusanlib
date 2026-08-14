require 'fileutils'

class Downstream
  GLOBAL_LOCK_KEY = 'downstreaming_global'.freeze
  LOCK_TTL = 15.minutes
  STATUS_TTL = 24.hours

  # Units matched in the downloader's progress log (aria2c and youtube-dl both
  # print "<done>MiB/<total>GiB(<pct>%)" lines). Values are read back to bytes.
  UNIT_BYTES = { 'B' => 1, 'KiB' => 1024, 'MiB' => 1024**2, 'GiB' => 1024**3, 'TiB' => 1024**4 }.freeze
  # aria2c lines also carry the current rate and time left, e.g.
  # "[#3f9afb 162MiB/1.0GiB(14%) CN:16 DL:396KiB ETA:40m2s]". Both the DL and
  # ETA parts are optional (youtube-dl's fallback output has neither).
  # rubocop:disable Layout/LineLength
  PROGRESS_RE = %r{(\d+(?:\.\d+)?) ?(B|KiB|MiB|GiB|TiB)/(\d+(?:\.\d+)?) ?(B|KiB|MiB|GiB|TiB) ?\((\d+)%\)(?: ?CN:\d+ DL:(\d+(?:\.\d+)?) ?(B|KiB|MiB|GiB|TiB))?(?: ?ETA:([A-Za-z0-9]+))?}
  # rubocop:enable Layout/LineLength

  # Kicks off the download in a background thread so the request returns
  # immediately. Returns :skipped when the video is already attached, :busy
  # when another download holds the global lock or this movie is already
  # downloading, and :ok once the background thread has been spawned.
  def self.enqueue(movie)
    return :skipped if movie.video_attached?
    return :busy if new(movie).downstreaming? || AppCache.exist?(GLOBAL_LOCK_KEY)

    Thread.new do
      service = new(movie)
      while AppCache.exist?(GLOBAL_LOCK_KEY)
        service.write_status(state: 'waiting', message: 'Waiting for another download to finish...')
        sleep 5
      end
      run(movie)
    rescue StandardError => e
      new(movie).write_status(state: 'failed', message: 'Download failed. Please contact the administrator.')
      App.logger.error(e.full_message)
    end
    :ok
  end

  def self.run(movie)
    new(movie).run
  end

  def self.status_key(movie)
    "downstream_status_#{movie.id}"
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

    if downstreaming?
      write_status(state: 'working', message: 'Download already in progress...')
      return :busy
    end

    unless AppCache.write(GLOBAL_LOCK_KEY, true, unless_exist: true, expires_in: LOCK_TTL)
      write_status(state: 'waiting', message: 'Waiting for another download to finish...')
      return :busy
    end

    begin
      AppCache.write(cache_key, true, expires_in: LOCK_TTL)

      make_storage_space
      download
      attach
      write_status(state: 'done', message: 'Preparing to stream...', redirect: "/streams/#{@movie.id}")
      :done
    rescue StandardError => e
      write_status(state: 'failed', message: 'Download failed. Please contact the administrator.')
      raise e
    ensure
      AppCache.delete(GLOBAL_LOCK_KEY)
      AppCache.delete(cache_key)
    end
  end

  def downstreaming?
    AppCache.exist?(cache_key)
  end

  def write_status(state:, message:, redirect: nil)
    AppCache.write(self.class.status_key(@movie), { state: state, message: message, redirect: redirect },
                   expires_in: STATUS_TTL)
  end

  private

  def cache_key
    @cache_key ||= "downstreaming_#{@movie.id}"
  end

  def make_storage_space
    return unless system("[ $(df / | tail -1 | awk '{print $5}' | sed 's/%//') -ge 80 ]")

    write_status(state: 'working', message: 'Making storage space...')
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

    write_status(state: 'working', message: 'Downloading...')
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
    write_status(state: 'working', message: 'Attaching...')
    @movie.attach_video_file(download_path, content_type: 'video/mp4')
  end

  def download_path
    self.class.download_path(@movie)
  end

  def youtube_dl_path
    ENV.fetch('YOUTUBE_DL_PATH', App::ROOT.join('venv', 'bin', 'youtube-dl').to_s)
  end
end
