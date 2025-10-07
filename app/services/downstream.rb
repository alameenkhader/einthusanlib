class Downstream
  def self.run(movie)
    new(movie).run
  end

  def initialize(movie)
    @movie = movie
  end

  def run
    return if @movie.video.attached?

    if downstreaming?
      broadcast_status_update("Downstreaming in progress...")
      return
    end

    Rails.cache.write(cache_key, true, expires_in: 10.minutes)

    make_storage_space
    download
    attach
    stream
    cleanup
  rescue => e
    broadcast_status_update("Failed")
    raise e
  ensure
    Rails.cache.delete(cache_key)
  end

  private

  def cache_key
    @cache_key ||= "downstreaming_#{@movie.id}"
  end

  def downstreaming?
    Rails.cache.exist?(cache_key)
  end

  def make_storage_space
    # Get disk usage percentage and check if it's >= 80%
    if system("[ $(df / | tail -1 | awk '{print $5}' | sed 's/%//') -ge 80 ]")
      broadcast_status_update("Making storage space...")
      # Find 3 oldest attached movie videos and purge them
      Movie.joins(:video_attachment)
        .where.not(id: @movie.id) # Don't delete current movie
        .order('active_storage_attachments.created_at ASC')
        .limit(3)
        .each do |movie|
          movie.video.purge if movie.video.attached?
        end
    end
  end

  def download
    return if File.exist?(download_path)

    broadcast_status_update("Downloading...")
    system("/app/venv/bin/youtube-dl -o '#{download_path}' '#{@movie.einthusan_url}'")
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
      [@movie, :show],
      action: "after",
      target: "downstream-status" ,
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

  def broadcast_status_update(message)
    Turbo::StreamsChannel.broadcast_replace_to(
      [@movie, :show],
      target: "downstream-status",
      partial: "movies/downstream_status",
      locals: { message: message, movie: @movie }
    )
  end
end
