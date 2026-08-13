class MoviesController < ApplicationController
  RECENT_CACHE_KEY = "recent_movies"
  RECENT_CACHE_TTL = 24.hours

  def index
    if params[:search]
      @movies = Search.run(params[:search])
    else
      @movies = recent_movies
    end
  end

  def show
    @movie = Movie.find(params[:id])

    redirect_to stream_path(@movie) if @movie.video.attached?
  end

  def download
    @movie = Movie.find(params[:id])

    Downstream.run(@movie) == :busy ? head(:conflict) : head(:ok)
  end

  private

  def recent_movies
    Rails.cache.fetch(RECENT_CACHE_KEY, expires_in: RECENT_CACHE_TTL) do
      Recent.run
      Movie.recent.limit(20).to_a
    end
  end
end
