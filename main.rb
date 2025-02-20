require 'logger'
require_relative 'config'
require_relative 'extractor'
require_relative 'downloader'

LOGGER = Logger.new(LOG_FILE)

def main
  run_id = Time.now.strftime("%Y%m%d%H%M%S")
  LOGGER.info("\n\n========================================")
  LOGGER.info("Starting main process, Run ID: #{run_id}, #{Time.now}")

  URLS.each do |url|
    LOGGER.info("Processing URL: #{url}")
    list = extract_movie_list(url)
    download_movies(list)
  end
end

main