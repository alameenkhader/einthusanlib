class Downstream
  GLOBAL_LOCK_KEY = "downstreaming_global"
  LOCK_TTL = 15.minutes

  def self.run(movie)
    new(movie).run
  end

  def initialize(movie)
    @movie = movie
  end

  def run
    return :skipped if @movie.video.attached?

    if downstreaming?
      broadcast_status_update("Download already in progress...")
      return :busy
    end

    unless Rails.cache.write(GLOBAL_LOCK_KEY, true, unless_exist: true, expires_in: LOCK_TTL)
      broadcast_status_update("Waiting for another download to finish...")
      return :busy
    end

    begin
      Rails.cache.write(cache_key, true, expires_in: LOCK_TTL)

      make_storage_space
      download
      attach
      stream
      cleanup
      :done
    rescue StandardError => e # re-raise so failures surface loudly; SystemExit/Interrupt still propagate
      broadcast_status_update("Download failed. Please contact the administrator.")
      raise e
    ensure
      Rails.cache.delete(GLOBAL_LOCK_KEY)
      Rails.cache.delete(cache_key)
    end
  end

  private

  def cache_key
    @cache_key ||= "downstreaming_#{@movie.id}"
  end

  def downstreaming?
    Rails.cache.exist?(cache_key)
  end

  def make_storage_space
    if system("[ $(df / | tail -1 | awk '{print $5}' | sed 's/%//') -ge 80 ]")
      broadcast_status_update("Making storage space...")
      Movie.joins(:video_attachment)
        .where.not(id: @movie.id)
        .order("active_storage_attachments.created_at ASC")
        .limit(3)
        .each do |movie|
          movie.video.purge if movie.video.attached?
        end
    end
  end

  def download
    return if File.exist?(download_path)

    broadcast_status_update("Downloading...")
    success = system("#{youtube_dl_path} -o '#{download_path}' '#{@movie.einthusan_url}'")
    raise "youtube-dl failed for movie #{@movie.id}" unless success || File.exist?(download_path)
  end

  def attach
    broadcast_status_update("Attaching...")
    @movie.video.attach(
      io: File.open(download_path),
      filename: File.basename(download_path)
    )
  end

  def cleanup
    File.delete(download_path) if File.exist?(download_path)
  end

  def stream
    broadcast_status_update("Preparing to stream...")
    Turbo::StreamsChannel.broadcast_action_to(
      [ @movie, :show ],
      action: "after",
      target: "downstream-status",
      html: <<~HTML
        <script>
              Turbo.visit('#{Rails.application.routes.url_helpers.stream_path(@movie)}')
          </script>
      HTML
    )
  end

  def download_path
    Rails.root.join("tmp", "downloads", "movie_#{@movie.id}.mp4").to_s
  end

  def youtube_dl_path
    ENV.fetch("YOUTUBE_DL_PATH", Rails.root.join("venv", "bin", "youtube-dl").to_s)
  end

  def broadcast_status_update(message)
    Turbo::StreamsChannel.broadcast_replace_to(
      [ @movie, :show ],
      target: "downstream-status",
      partial: "movies/downstream_status",
      locals: { message: message, movie: @movie }
    )
  end
end
