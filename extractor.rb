require 'nokogiri'
require 'open-uri'
require 'fileutils'
require 'date'
require_relative 'config'
require_relative 'downloader'

def extract_movie_list(url)
  html_content = URI.open(url).read
  soup = Nokogiri::HTML(html_content)

  # Find the section after the title 'Popularity View Last 30 Days'
  popularity_section = soup.at_css('.results-info:contains("Popularity View Last 30 Days")')
  movies_list = popularity_section&.next_element

  return [] unless movies_list

  movies = movies_list.css('ul li').map do |movie|
    block2 = movie.at_css('.block2')
    next unless block2

    title = block2.at_css('.title h3')&.text || "Unknown Title"
    image_url = movie.at_css('.block1 img')&.[]('src') || "No Image URL"
    relative_url = block2.at_css('.title')&.[]('href') || "No URL"
    release_date = movie.at_css('.block3 .stats time')&.[]('datetime')
    release_datetime = release_date ? DateTime.parse(release_date) : DateTime.new(1970)
    full_url = BASE_URL + relative_url
    file_name = "#{title.downcase.gsub(/\s+/, '_')}.mp4"
    file_path = "#{DOWNLOAD_PATH}/#{file_name}"
    {
      title: title,
      image_url: image_url,
      einthusan_url: full_url,
      file_name: file_name,
      file_path: file_path,
      release_date: release_datetime
    }
  end.compact

  movies.first(5)
end
