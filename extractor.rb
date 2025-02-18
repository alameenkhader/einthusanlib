require 'nokogiri'
require 'open-uri'
require 'fileutils'
require_relative 'config'
require_relative 'downloader'

def extract_movie_list
  html_content = URI.open(URL).read
  soup = Nokogiri::HTML(html_content)

  movies = []

  # Find the section after the title 'Popularity View Last 2 Months'
  popularity_section = soup.at_css('.results-info:contains("Popularity View Last 2 Months")')
  movies_list = popularity_section&.next_element

  movies_list.css('ul li').each do |movie|
    block2 = movie.at_css('.block2')
    next unless block2

    title = block2.at_css('.title h3')&.text || "Unknown Title"
    image_url = movie.at_css('.block1 img')&.[]('src') || "No Image URL"
    relative_url = block2.at_css('.title')&.[]('href') || "No URL"
    full_url = BASE_URL + relative_url
    file_name = "#{title.downcase.gsub(/\s+/, '_')}.mp4"
    file_path = "#{DOWNLOAD_PATH}/#{file_name}"
    movies << {
      title: title,
      image_url: image_url,
      einthusan_url: full_url,
      file_name: file_name,
      file_path: file_path
    }
  end

  movies
end
