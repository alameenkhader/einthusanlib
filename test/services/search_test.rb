require "test_helper"

# Touch the constant so Zeitwerk autoloads the service (and its `require
# "open-uri"`) before any stubbing runs. Requiring open-uri redefines
# URI.open, which would silently clobber a Minitest stub installed first.
Search

class SearchTest < ActiveSupport::TestCase
  def stub_page(html)
    URI.stub(:open, ->(*) { StringIO.new(html) }) { yield }
  end

  test "returns an empty array for a blank query without hitting the network" do
    URI.stub(:open, ->(*) { raise "should not fetch" }) do
      assert_equal [], Search.run("")
      assert_equal [], Search.run(nil)
    end
  end

  test "parses the page and creates movies" do
    html = einthusan_list_html([ { title: "Found", year: 2020, slug: "found" } ])

    movies = stub_page(html) { Search.run("found") }

    assert_equal 1, movies.size
    movie = movies.first
    assert_equal "Found", movie.title
    assert_equal "https://einthusan.tv/movie/found", movie.einthusan_url
    assert_equal 2020, movie.released_at.year
  end

  test "returns at most the first four results" do
    html = einthusan_list_html((1..5).map { |i| { title: "Movie #{i}", year: 2000 + i, slug: "m#{i}" } })

    movies = stub_page(html) { Search.run("any") }

    assert_equal 4, movies.size
    assert_equal [ "Movie 1", "Movie 2", "Movie 3", "Movie 4" ], movies.map(&:title)
  end

  test "keeps existing movies instead of duplicating when the page is parsed again" do
    stub_page(einthusan_list_html([ { title: "Found", year: 2020, slug: "found" } ])) { Search.run("found") }

    stub_page(einthusan_list_html([ { title: "Found", year: 2020, slug: "found" } ])) { Search.run("found") }

    assert_equal 1, Movie.where(einthusan_url: "https://einthusan.tv/movie/found").count
  end

  test "returns nil when the network fails" do
    URI.stub(:open, ->(*) { raise Errno::ECONNREFUSED }) do
      assert_nil Search.run("found")
    end
  end
end
