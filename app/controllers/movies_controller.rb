class MoviesController < ApplicationController
  before_action :movie, only: [:show]
  def index
    if params[:search]
      @movies = Search.run(params[:search])
    else
      @movies = Movie.recent.limit(20)
    end
  end

  def show
    @movie = Movie.find(params[:id])
    DownstreamJob.perform_later(params[:id])
  end
end
