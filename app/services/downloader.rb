require 'fileutils'

# Single in-flight downloader with no persistent state. A download only runs
# while someone has pasted a URL; the scheduler, queue, and database are gone.
#
# State lives in memory (Downloader.current) and is naturally lost on restart:
# a crashed download just leaves files behind, which are wiped on boot and on
# the next start. One download at a time; new pastes while busy are rejected.
class Downloader
  STATE_KEYS = %i[url filename state error started_at].freeze
  IDLE = { url: nil, filename: nil, state: :idle, error: nil, started_at: nil }.freeze

  # Files in the completed-movies directory newer than this cutoff are kept;
  # anything older is deleted before a new download starts (keep the last 3).
  KEEP_LATEST = 3

  # Many CDNs throttle per-connection (single-connection downloads crawl at
  # ~10-25 KiB/s). When aria2c is available we fan out with 16 parallel
  # connections and min split 1M, which measured ~2.3 MB/s aggregate and gets a
  # 1.1 GiB movie done inside the 6h signed-URL TTL. Falls back to the plain
  # youtube-dl command when aria2c is not installed.
  # rubocop:disable Layout/LineLength
  PROGRESS_RE = %r{(\d+(?:\.\d+)?) ?(B|KiB|MiB|GiB|TiB)/(\d+(?:\.\d+)?) ?(B|KiB|MiB|GiB|TiB) ?\((\d+)%\)(?: ?CN:\d+ DL:(\d+(?:\.\d+)?) ?(B|KiB|MiB|GiB|TiB))?(?: ?ETA:([A-Za-z0-9]+))?}
  # rubocop:enable Layout/LineLength
  UNIT_BYTES = { 'B' => 1, 'KiB' => 1024, 'MiB' => 1024**2, 'GiB' => 1024**3, 'TiB' => 1024**4 }.freeze

  class << self
    attr_reader :current

    def idle!
      @current = IDLE.dup
    end

    def downloading?
      @current && @current[:state] == :downloading
    end

    # Validates the URL and starts a download. Returns :busy when one is already
    # running, :invalid when the URL is not a well-formed http(s) URL, otherwise
    # :started.
    def start(url)
      return :busy if downloading?

      clean_url = url.to_s.strip
      return :invalid unless valid_url?(clean_url)

      filename = "movie_#{Time.now.to_i}.mp4"
      cleanup_library
      @current = {
        url: clean_url,
        filename: filename,
        state: :downloading,
        error: nil,
        started_at: Time.now
      }

      Thread.new do
        Downloader.run_download(@current)
      end
      :started
    end

    # Replaces the movies dir with just the KEEP_LATEST newest files.
    def cleanup_library
      files = Dir.glob(App.movies_dir.join('*.mp4'))
                 .sort_by { |path| File.mtime(path) }
                 .reverse
      files.drop(KEEP_LATEST).each { |path| FileUtils.rm_f(path) }
    end

    # Removes partial/control files from earlier (possibly crashed) runs.
    def cleanup_stale_partials
      Dir.glob(App.downloads_dir.join('movie_*.mp4.{part,aria2,log}')).each do |path|
        FileUtils.rm_f(path)
      end
    end

    def downloads_dir
      App.downloads_dir
    end

    def movies_dir
      App.movies_dir
    end

    def status
      current = @current || IDLE
      current.merge(progress: progress_for(current)).merge(state: current[:state])
    end

    def progress_for(download)
      return nil unless download && download[:filename]

      path = progress_path(download[:filename])
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

    def download_path(filename)
      downloads_dir.join(filename).to_s
    end

    def progress_path(filename)
      "#{download_path(filename)}.log"
    end

    # "40m2s" / "2h16s" / "1m" / "0s" -> seconds; nil for "Unk" or anything else.
    def parse_eta(raw)
      return nil if raw.nil?

      m = raw.match(/\A(?:(?<h>\d+)h)?(?:(?<m>\d+)m)?(?:(?<s>\d+)s)?\z/)
      return nil if m.nil? || (m[:h].nil? && m[:m].nil? && m[:s].nil?)

      (m[:h].to_i * 3600) + (m[:m].to_i * 60) + m[:s].to_i
    end

    def rate_to_bytes(value, unit)
      return nil if value.nil? || unit.nil?

      (value.to_f * UNIT_BYTES.fetch(unit)).to_i
    end

    # Runs the download in a background thread and updates @current as it goes.
    # Runs outside the request cycle, so @current is touched on this thread.
    def run_download(download)
      cleanup_stale_partials
      download_in_progress(download)
    rescue StandardError => e
      @current = download.merge(state: :error, error: e.message)
      App.logger.error("downloader: #{e.full_message}")
    end

    def valid_url?(url)
      uri = URI.parse(url)
      uri.is_a?(URI::HTTP) && uri.host
    rescue URI::InvalidURIError
      false
    end

    def youtube_dl_path
      ENV.fetch('YOUTUBE_DL_PATH', App::ROOT.join('venv', 'bin', 'youtube-dl').to_s)
    end

    private

    def download_in_progress(download)
      path = download_path(download[:filename])
      progress_log = progress_path(download[:filename])

      # Capture the downloader's output so progress can be parsed for the UI.
      # Redirecting (not a tty) makes aria2c/youtube-dl print newline-separated
      # "<done>/<total>(<pct>%)" progress lines.
      success = if system('command -v aria2c >/dev/null 2>&1')
                  system("#{youtube_dl_path} -o '#{path}' " \
                         '--external-downloader aria2c ' \
                         "--external-downloader-args '-x 16 -s 16 -k 1M " \
                         "--summary-interval=5' '#{download[:url]}' " \
                         "> '#{progress_log}' 2>&1")
                else
                  system("#{youtube_dl_path} -o '#{path}' '#{download[:url]}' " \
                         "> '#{progress_log}' 2>&1")
                end
      raise 'youtube-dl failed' unless success || File.exist?(path)

      finalize(download)
    end

    def finalize(download)
      path = download_path(download[:filename])
      FileUtils.mkdir_p(movies_dir)
      FileUtils.mv(path, movies_dir.join(download[:filename]))
      @current = download.merge(state: :done, error: nil)
    end
  end
end
