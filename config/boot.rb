ENV['RACK_ENV'] ||= ENV['RAILS_ENV'] || 'development'

require 'bundler/setup'

groups = [ :default ]
groups << ENV['RACK_ENV'].to_sym if %w[development test].include?(ENV['RACK_ENV'])
Bundler.require(*groups)

require 'active_support/all'
require 'active_record'
require 'logger'
require 'securerandom'
require 'fileutils'
require 'pathname'
require 'yaml'
require 'erb'
require 'json'
require 'date'
require 'cgi'
require 'open-uri'

module App
  ROOT = Pathname.new(File.expand_path('..', __dir__))

  def self.env
    ENV.fetch('RACK_ENV', nil)
  end

  def self.logger
    @logger ||= Logger.new($stdout)
  end

  # Stable secret for signed session cookies. Uses ENV["SECRET_KEY_BASE"] when
  # set, otherwise generates and persists a secret in storage/ so it stays
  # stable across restarts (same pattern as the old Rails production config).
  def self.session_secret
    @session_secret ||= ENV['SECRET_KEY_BASE'].presence || begin
      path = ROOT.join('storage', '.secret_key_base')
      if File.exist?(path)
        File.read(path).strip
      else
        FileUtils.mkdir_p(path.dirname)
        secret = SecureRandom.hex(64)
        File.write(path, secret)
        secret
      end
    end
  end
end

FileUtils.mkdir_p(App::ROOT.join('storage', 'movies'))
FileUtils.mkdir_p(App::ROOT.join('tmp', 'downloads'))

db_configuration = YAML.safe_load(
  ERB.new(File.read(App::ROOT.join('config', 'database.yml'))).result,
  aliases: true
)

ActiveRecord::Base.configurations = ActiveRecord::DatabaseConfigurations.new(db_configuration)
ActiveRecord::Base.establish_connection(App.env.to_sym)
ActiveRecord::Base.logger = App.logger if ENV['RAILS_LOG_TO_STDOUT']
ActiveRecord::Base.connection.execute('PRAGMA journal_mode = WAL')

require_relative '../app/models/application_record'
require_relative '../app/models/movie'
require_relative '../app/models/cache_entry'
require_relative '../app/lib/app_cache'
require_relative '../app/helpers/formatting'
require_relative '../app/services/recent'
require_relative '../app/services/search'
require_relative '../app/services/downstream'
require_relative '../app/services/scheduler'
require_relative '../app/services/status'
