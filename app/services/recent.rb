require "nokogiri"
require "open-uri"

# Designed to fetch and parse recent movies from Einthusan.
class Recent
  BASE_URL = "https://einthusan.tv"

  def self.run
    new.call
  end

  def call
    url = "#{BASE_URL}/movie/results/?find=Recent&lang=malayalam"

    html_content = URI.open(url).read
    parse_results(html_content)
  end

  private

  def parse_results(html_content)
    soup = Nokogiri::HTML(html_content)

    movie_elements = soup.css("#UIMovieSummary ul li").select { |li| li.css(".block2").any? }

    movies = movie_elements.map do |movie|
      extract_movie_data(movie)
    end.compact

    movies.compact
  end

  def extract_movie_data(movie_element)
    block2 = movie_element.at_css(".block2")
    return nil unless block2

    title = block2.at_css(".title h3")&.text&.strip || "Unknown Title"
    image_url = movie_element.at_css(".block1 img")&.[]("src") || ""

    image_url = image_url.sub(/^\/\//, "https://") if image_url.start_with?("//")

    relative_url = block2.at_css(".title")&.[]("href") || ""
    full_url = relative_url.start_with?("http") ? relative_url : "#{BASE_URL}#{relative_url}"

    release_info = block2.at_css(".info p")&.text
    release_year = extract_year(release_info) if release_info
    release_datetime = release_year ? DateTime.new(release_year) : DateTime.new(1970)

    Movie.find_or_create_by(einthusan_url: full_url) do |movie|
      movie.title = title
      movie.image_url = image_url
      movie.released_at = release_datetime
    end
  end

  def extract_year(text)
    year_match = text.match(/(\d{4})/)
    year_match ? year_match[1].to_i : nil
  end
end
