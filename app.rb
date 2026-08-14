require_relative 'config/boot'

require 'sinatra/base'
require 'rack/protection'
require 'json'

class Chalaflix < Sinatra::Base
  RECENT_CACHE_KEY = 'recent_movies'.freeze
  RECENT_CACHE_TTL = 24.hours

  configure do
    set :root, __dir__
    set :views, File.join(__dir__, 'views')
    set :public_folder, File.join(__dir__, 'public')
    set :environment, App.env.to_sym
    set :sessions, secret: App.session_secret, expire_after: 30.days
    set :logging, true
    set :show_exceptions, false
    set :raise_errors, false
    set :dump_errors, true

    # Token-based CSRF (rack-protection) mirrors the old Rails meta tag +
    # X-CSRF-Token header flow. AuthenticityToken is opt-in in rack-protection
    # 4, and we deny (403) on failure rather than the default drop_session,
    # which just clears the session and lets the request through.
    protect_use = [ :authenticity_token ]
    protect_use = [] if App.env == 'test'
    set :protection,
        use: protect_use,
        except: %i[ip_spoofing remote_token remote_referrer session_hijacking],
        reaction: :deny
  end

  get '/' do
    @movies = if params[:search] && !params[:search].strip.empty?
                Search.run(params[:search])
              else
                recent_movies
              end
    erb :index
  end

  get '/movies/:id' do
    @movie = Movie.find(params[:id].to_i)

    redirect stream_path(@movie) if @movie.video_attached?

    @status = Status.for(@movie)

    erb :show
  end

  post '/movies/:id/download' do
    @movie = Movie.find(params[:id].to_i)

    halt 409 if Downstream.enqueue(@movie) == :busy

    halt 200
  end

  get '/movies/:id/status' do
    @movie = Movie.find(params[:id].to_i)

    content_type :json
    Status.for(@movie).to_json
  end

  get '/streams/:id' do
    @movie = Movie.find(params[:id].to_i)

    halt 404 unless @movie.video_attached?

    send_file @movie.video_path, type: @movie.video_content_type, disposition: 'inline'
  end

  helpers do
    def movies_path
      '/'
    end

    def movie_path(movie)
      "/movies/#{movie.id}"
    end

    def stream_path(movie)
      "/streams/#{movie.id}"
    end

    def download_movie_path(movie)
      "/movies/#{movie.id}/download"
    end

    def status_movie_path(movie)
      "/movies/#{movie.id}/status"
    end

    def recent_movies
      AppCache.fetch(RECENT_CACHE_KEY, expires_in: RECENT_CACHE_TTL) do
        Recent.run
        Movie.recent.limit(20).to_a
      end
    end
  end

  error ActiveRecord::RecordNotFound do
    halt 404
  end

  error do
    App.logger.error(env['sinatra.error']&.full_message)
    halt 500
  end
end
