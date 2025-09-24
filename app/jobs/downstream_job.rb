class DownstreamJob < ApplicationJob
  queue_as :default

  def perform(movie_id)
    movie = Movie.find(movie_id)
    Downstream.run(movie)
  end
end
