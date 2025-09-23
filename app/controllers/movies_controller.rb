class MoviesController < ApplicationController
  def index
    # @movies = load_movies_from_directory
    p params

    p Search.run(params[:search])
  end
end
