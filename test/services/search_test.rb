require 'test_helper'

class SearchTest < Minitest::Test
  def stub_page(html, &)
    URI.stub(:open, ->(*) { StringIO.new(html) }, &)
  end

  def test_returns_an_empty_array_for_a_blank_query_without_hitting_the_network
    URI.stub(:open, ->(*) { raise 'should not fetch' }) do
      assert_equal [], Search.run('')
      assert_equal [], Search.run(nil)
    end
  end

  def test_parses_the_page_and_creates_movies
    html = einthusan_list_html([ { title: 'Found', year: 2020, slug: 'found' } ])

    movies = stub_page(html) { Search.run('found') }

    assert_equal 1, movies.size
    movie = movies.first
    assert_equal 'Found', movie.title
    assert_equal 'https://einthusan.tv/movie/found', movie.einthusan_url
    assert_equal 2020, movie.released_at.year
  end

  def test_returns_at_most_the_first_four_results
    html = einthusan_list_html((1..5).map { |i| { title: "Movie #{i}", year: 2000 + i, slug: "m#{i}" } })

    movies = stub_page(html) { Search.run('any') }

    assert_equal 4, movies.size
    assert_equal [ 'Movie 1', 'Movie 2', 'Movie 3', 'Movie 4' ], movies.map(&:title)
  end

  def test_keeps_existing_movies_instead_of_duplicating_when_the_page_is_parsed_again
    stub_page(einthusan_list_html([ { title: 'Found', year: 2020, slug: 'found' } ])) { Search.run('found') }

    stub_page(einthusan_list_html([ { title: 'Found', year: 2020, slug: 'found' } ])) { Search.run('found') }

    assert_equal 1, Movie.where(einthusan_url: 'https://einthusan.tv/movie/found').count
  end

  def test_raises_when_the_network_fails
    URI.stub(:open, ->(*) { raise Errno::ECONNREFUSED }) do
      assert_raises(Errno::ECONNREFUSED) { Search.run('found') }
    end
  end
end
