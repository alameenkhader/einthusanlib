require "nokogiri"
require "open-uri"

class Search
  BASE_URL = "https://einthusan.tv"

  def self.run(query)
    new(query).call
  end

  def initialize(query)
    @query = query
  end

  def call
    return [] if @query.blank?

    search_url = "#{BASE_URL}/movie/results/?query=#{CGI.escape(@query)}"

    html_content = URI.open(search_url).read
    parse_results(html_content)
  end

  private

  def parse_results(html_content)
    soup = Nokogiri::HTML(html_content)

    # Find movie results - typically in a results container
    movie_elements = soup.css("ul li").select { |li| li.css(".block2").any? }

    movies = movie_elements.first(4).map do |movie|
      extract_movie_data(movie)
    end.compact

    movies.compact
  end

  def extract_movie_data(movie_element)
    block2 = movie_element.at_css(".block2")
    return nil unless block2

    title = block2.at_css(".title h3")&.text&.strip || "Unknown Title"
    image_url = movie_element.at_css(".block1 img")&.[]("src") || ""

    # Fix image URL if it's protocol-relative
    image_url = image_url.sub(/^\/\//, "http://") if image_url.start_with?("//")

    relative_url = block2.at_css(".title")&.[]("href") || ""
    full_url = relative_url.start_with?("http") ? relative_url : "#{BASE_URL}#{relative_url}"

    release_date = movie_element.at_css(".block3 .stats time")&.[]("datetime")
    release_datetime = DateTime.parse(release_date) if release_date

    Movie.find_or_create_by(einthusan_url: full_url) do |movie|
      movie.title = title
      movie.image_url = image_url
      movie.released_at = release_datetime || DateTime.new(1970)
    end
  end
end
