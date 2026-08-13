require "test_helper"

# Touch the constant so Zeitwerk autoloads the service (and its `require
# "open-uri"`) before any stubbing runs. Requiring open-uri redefines
# URI.open, which would silently clobber a Minitest stub installed first.
Recent

class RecentTest < ActiveSupport::TestCase
  def stub_page(html)
    URI.stub(:open, ->(*) { StringIO.new(html) }) { yield }
  end

  test "parses the page and creates movies" do
    html = einthusan_list_html([ { title: "Oldie", year: 1999, slug: "oldie" } ])

    movies = stub_page(html) { Recent.run }

    assert_equal 1, movies.size
    movie = movies.first
    assert_equal "Oldie", movie.title
    assert_equal "https://einthusan.tv/movie/oldie", movie.einthusan_url
    assert_equal 1999, movie.released_at.year
    assert_equal "https://cdn.example.com/oldie.jpg", movie.image_url
  end

  test "keeps existing movies instead of duplicating when the page is parsed again" do
    stub_page(einthusan_list_html([ { title: "Oldie", year: 1999, slug: "oldie" } ])) { Recent.run }

    stub_page(einthusan_list_html([ { title: "Oldie", year: 1999, slug: "oldie" } ])) { Recent.run }

    assert_equal 1, Movie.where(einthusan_url: "https://einthusan.tv/movie/oldie").count
  end

  test "creates a movie per result and returns them" do
    html = einthusan_list_html([
      { title: "One", year: 2001, slug: "one" },
      { title: "Two", year: 2002, slug: "two" }
    ])

    movies = stub_page(html) { Recent.run }

    assert_equal 2, movies.size
    assert_equal %w[One Two], movies.map(&:title)
  end

  test "returns nil when the network fails" do
    URI.stub(:open, ->(*) { raise Errno::ECONNREFUSED }) do
      assert_nil Recent.run
    end
  end
end
