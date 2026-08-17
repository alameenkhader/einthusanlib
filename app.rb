require_relative 'config/boot'

require 'sinatra/base'
require 'json'

class Chalaflix < Sinatra::Base
  configure do
    set :root, __dir__
    set :views, File.join(__dir__, 'views')
    set :public_folder, File.join(__dir__, 'public')
    set :environment, App.env.to_sym
    set :show_exceptions, false
    set :raise_errors, false
    set :dump_errors, true
  end

  get '/' do
    @status = Downloader.status
    @library = library_files
    @notice = params[:notice]
    erb :index
  end

  post '/downloads' do
    result = Downloader.start(params[:url])
    notice = case result
             when :started then nil
             when :busy then 'A download is already in progress.'
             when :invalid then 'That URL is not supported.'
             end
    redirect notice ? "/?notice=#{URI.encode_www_form_component(notice)}" : '/'
  end

  get '/status.json' do
    content_type :json
    Downloader.status.to_json
  end

  get '/watch/:filename' do
    filename = params[:filename].to_s
    halt 404 unless filename.match?(/\A[A-Za-z0-9._-]+\z/)

    path = File.join(App.movies_dir, filename)
    halt 404 unless File.file?(path)

    send_file path, type: 'video/mp4', disposition: 'inline'
  end

  helpers Formatting

  helpers do
    def library_files
      Dir.glob(App.movies_dir.join('*'))
         .sort_by { |path| File.mtime(path) }
         .reverse
         .map { |path| { name: File.basename(path), mtime: File.mtime(path) } }
    end
  end

  error do
    App.logger.error(env['sinatra.error']&.full_message)
    halt 500
  end
end
