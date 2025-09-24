class Downstream
  def self.run(movie)
    new(movie).run
  end

  def initialize(movie)
    @movie = movie
  end

  def run
    return if @movie.video.attached?

    download
    attach
    cleanup
  rescue => e
    broadcast_status_update("Failed")
    raise e
  end

  private

  def download
    puts 'in download'
    puts 'file exist?', File.exist?(download_path)
    return if File.exist?(download_path)

    broadcast_status_update("Downloading...")
    # Findout if needs to resume or find out another job is already downloading then exit
    # system("youtube-dl -o '#{download_path}' '#{@movie.einthusan_url}'")
  end

  def attach
    # broadcast_status_update("Attaching...")
    # @movie.video.attach(
    #   io: File.open(download_path),
    #   filename: File.basename(download_path)
    # )
  end

  def cleanup
    puts 'in cleanup'
    puts 'file exist?', File.exist?(download_path)
    return unless File.exist?(download_path)
    broadcast_status_update("Cleaning...")
    File.delete(download_path)
  end

  def download_path
    "/tmp/movie_#{@movie.id}.mp4"
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