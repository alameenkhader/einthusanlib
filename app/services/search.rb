require 'nokogiri'
require 'open-uri'

class Search
  BASE_URL = 'https://einthusan.tv'

  def self.run(query)
    new(query).call
  end

  def initialize(query)
    @query = query
  end

  def call
    return [] if @query.blank?

    search_url = "#{BASE_URL}/movie/results/?query=#{CGI.escape(@query)}"

    begin
      html_content = URI.open(search_url).read
      parse_results(html_content)
    rescue => e
      Rails.logger.error "Search error: #{e.message}"
      []
    end
  end

  private

  def parse_results(html_content)
    soup = Nokogiri::HTML(html_content)

    # Find movie results - typically in a results container
    movie_elements = soup.css('ul li').select { |li| li.css('.block2').any? }

    movies = movie_elements.first(4).map do |movie|
      extract_movie_data(movie)
    end.compact

    movies
  end

  def extract_movie_data(movie_element)
    block2 = movie_element.at_css('.block2')
    return nil unless block2

    title = block2.at_css('.title h3')&.text&.strip || "Unknown Title"
    image_url = movie_element.at_css('.block1 img')&.[]('src') || ""

    # Fix image URL if it's protocol-relative
    image_url = image_url.sub(/^\/\//, 'http://') if image_url.start_with?('//')

    relative_url = block2.at_css('.title')&.[]('href') || ""
    full_url = relative_url.start_with?('http') ? relative_url : "#{BASE_URL}#{relative_url}"

    release_date = movie_element.at_css('.block3 .stats time')&.[]('datetime')
    release_datetime = if release_date
                         begin
                           DateTime.parse(release_date)
                         rescue
                           DateTime.new(1970)
                         end
                       else
                         DateTime.new(1970)
                       end

    {
      title: title,
      image_url: image_url,
      einthusan_url: full_url,
      release_date: release_datetime
    }
  end
end