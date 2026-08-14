source 'https://rubygems.org'

# Web framework: Sinatra (Rack 3) — no nokogiri anywhere in this bundle.
gem 'puma', '>= 5.0'
gem 'rackup', '~> 2.2'
gem 'sinatra', '~> 4.1'

# Data layer: standalone ActiveRecord + SQLite (single native gem to compile).
gem 'activerecord', '~> 8.0'
gem 'rake'
gem 'sqlite3', '>= 2.1'

# Pure-Ruby HTML parser (replaces nokogiri).
gem 'oga', '~> 3.5'

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[windows jruby]

group :development do
  gem 'rubocop', require: false
end

group :test do
  gem 'minitest', require: false
  gem 'rack-test', require: false
end
