require_relative 'config'
require_relative 'extractor'
require_relative 'downloader'
require_relative 'cleaner'
require_relative 'html_builder'

def main
  run_id = Time.now.strftime("%Y%m%d%H%M%S")
  LOGGER.info("\n\n========================================")
  LOGGER.info("Starting main process, Run ID: #{run_id}, #{Time.now}")

  clean_old_downloads
  teardown_html_page

  # Use reduce to merge all media lists while still downloading each individually
  all_media = URLS.reduce([]) do |media_accumulator, url|
    LOGGER.info("Processing URL: #{url}")
    list = extract_movie_list(url)
    download_movies(list)
    media_accumulator + list  # This creates a new array combining both
  end

  # Build HTML page with all merged media
  build_html_page(all_media)
end

main
