class DownstreamJob < ApplicationJob
  queue_as :default

  retry_on StandardError, attempts: 0

  def perform(movie_id)
    movie = Movie.find(movie_id)
    Downstream.run(movie)
  end
end
