class MoviesController < ApplicationController
  def index
    if params[:search]
      @movies = Search.run(params[:search])
    else
      @movies = Movie.recent.limit(20)
    end
  end
end
