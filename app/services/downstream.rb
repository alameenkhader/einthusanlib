class Downstream
  def self.run(movie)
    new(movie).run
  end

  def initialize(movie)
    @movie = movie
  end

  def run
    DownloadVideoJob.perform_later(@movie.id)
  end
end