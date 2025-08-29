require 'logger'
require_relative 'config'
require_relative 'extractor'
require_relative 'downloader'
require_relative 'cleaner'
require_relative 'html_builder'

LOGGER = Logger.new(LOG_FILE)

def main
  run_id = Time.now.strftime("%Y%m%d%H%M%S")
  LOGGER.info("\n\n========================================")
  LOGGER.info("Starting main process, Run ID: #{run_id}, #{Time.now}")

  clean_old_downloads
  teardown_html_page

  URLS.each do |url|
    LOGGER.info("Processing URL: #{url}")
    list = extract_movie_list(url)
    download_movies(list)
    build_html_page(list)
  end
end

main
