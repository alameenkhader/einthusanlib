require 'logger'
require_relative 'config'
require_relative 'extractor'
require_relative 'downloader'

LOGGER = Logger.new(LOG_FILE)

def main
  run_id = Time.now.strftime("%Y%m%d%H%M%S")
  LOGGER.info("\n\n========================================")
  LOGGER.info("Starting main process, Run ID: #{run_id}, #{Time.now}")

  list = extract_movie_list

  download_movies(list)
end

main