class MoviesController < ApplicationController
  def index
    if params[:search]
      @movies = Search.run(params[:search])
    else
      @movies = Movie.recent.limit(20)
    end
  end

  def show
    @movie = Movie.find(params[:id])
    DownstreamJob.set(wait: 5.seconds).perform_later(params[:id])
  end
end
