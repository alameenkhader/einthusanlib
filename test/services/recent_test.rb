require 'test_helper'

class RecentTest < Minitest::Test
  def stub_page(html, &)
    URI.stub(:open, ->(*) { StringIO.new(html) }, &)
  end

  def test_parses_the_page_and_creates_movies
    html = einthusan_list_html([ { title: 'Oldie', year: 1999, slug: 'oldie' } ])

    movies = stub_page(html) { Recent.run }

    assert_equal 1, movies.size
    movie = movies.first
    assert_equal 'Oldie', movie.title
    assert_equal 'https://einthusan.tv/movie/oldie', movie.einthusan_url
    assert_equal 1999, movie.released_at.year
    assert_equal 'https://cdn.example.com/oldie.jpg', movie.image_url
  end

  def test_keeps_existing_movies_instead_of_duplicating_when_the_page_is_parsed_again
    stub_page(einthusan_list_html([ { title: 'Oldie', year: 1999, slug: 'oldie' } ])) { Recent.run }

    stub_page(einthusan_list_html([ { title: 'Oldie', year: 1999, slug: 'oldie' } ])) { Recent.run }

    assert_equal 1, Movie.where(einthusan_url: 'https://einthusan.tv/movie/oldie').count
  end

  def test_creates_a_movie_per_result_and_returns_them
    html = einthusan_list_html([
                                 { title: 'One', year: 2001, slug: 'one' },
                                 { title: 'Two', year: 2002, slug: 'two' }
                               ])

    movies = stub_page(html) { Recent.run }

    assert_equal 2, movies.size
    assert_equal %w[One Two], movies.map(&:title)
  end

  def test_raises_when_the_network_fails
    URI.stub(:open, ->(*) { raise Errno::ECONNREFUSED }) do
      assert_raises(Errno::ECONNREFUSED) { Recent.run }
    end
  end
end
