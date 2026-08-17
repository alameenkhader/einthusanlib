ENV['RACK_ENV'] ||= ENV['RAILS_ENV'] || 'development'

require 'bundler/setup'

groups = [ :default ]
groups << ENV['RACK_ENV'].to_sym if %w[development test].include?(ENV['RACK_ENV'])
Bundler.require(*groups)

require 'logger'
require 'fileutils'
require 'pathname'
require 'json'
require 'uri'
require 'erb'

module App
  ROOT = Pathname.new(File.expand_path('..', __dir__))

  def self.env
    ENV.fetch('RACK_ENV', nil)
  end

  def self.logger
    @logger ||= Logger.new($stdout)
  end

  # Directory that holds finished, watchable movies.
  def self.movies_dir
    ROOT.join('storage', 'movies')
  end

  # Directory where an in-progress download lands before it is moved to
  # movies_dir. Leftovers here (a crashed run) are wiped on boot.
  def self.downloads_dir
    ROOT.join('tmp', 'downloads')
  end
end

FileUtils.mkdir_p(App.movies_dir)
FileUtils.mkdir_p(App.downloads_dir)

# Boot-time self-healing: any partial/control file left by a crashed download is
# stale by definition (there is no in-flight download on boot), so remove them.
Dir.glob(App.downloads_dir.join('movie_*.mp4.{part,aria2,log}')).each do |path|
  FileUtils.rm_f(path)
end

require_relative '../app/helpers/formatting'
require_relative '../app/services/downloader'
