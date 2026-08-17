ENV['RACK_ENV'] = 'test'

require_relative '../config/boot'
require_relative '../app'

require 'minitest/autorun'
require 'minitest/mock'
require 'rack/test'

class Minitest::Test
  include Rack::Test::Methods

  def app
    Chalaflix
  end

  def setup
    Downloader.idle!
    Downloader.cleanup_stale_partials
    FileUtils.rm_rf(App.movies_dir)
    FileUtils.mkdir_p(App.movies_dir)
  end
end
