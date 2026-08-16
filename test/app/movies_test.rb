require 'test_helper'

class MoviesTest < Minitest::Test
  def test_index_scrapes_once_per_24h
    calls = 0
    Recent.stub(:run, lambda {
      calls += 1
      []
    }) do
      get '/'
      get '/'
    end

    assert_equal 1, calls
  end

  def test_index_caches_the_recent_movie_list
    Recent.stub(:run, -> { [] }) { get '/' }

    assert_equal 200, last_response.status
    assert AppCache.read(Chalaflix::RECENT_CACHE_KEY).is_a?(Array)
  end

  def test_index_renders_the_recent_movies_from_the_database
    Movie.create!(
      title: 'Recent Hit',
      einthusan_url: 'https://einthusan.tv/movie/recent',
      image_url: 'https://cdn.example.com/recent.jpg',
      released_at: DateTime.new(2020)
    )
    Recent.stub(:run, -> { [] }) { get '/' }

    assert_equal 200, last_response.status
    assert_includes last_response.body, 'Recent Hit'
    assert_includes last_response.body, 'https://cdn.example.com/recent.jpg'
  end

  def test_index_with_a_search_term_delegates_to_search
    movie = Movie.create!(
      title: 'Matched Movie',
      einthusan_url: 'https://einthusan.tv/movie/match',
      released_at: DateTime.new(2020)
    )
    query = nil

    Search.stub(:run, lambda { |q|
      query = q
      [ movie ]
    }) do
      get '/', search: 'Term'
    end

    assert_equal 200, last_response.status
    assert_equal 'Term', query
    assert_includes last_response.body, 'Matched Movie'
  end

  def test_index_renders_a_warning_when_search_finds_nothing
    Search.stub(:run, ->(_q) { [] }) { get '/', search: 'Nope' }

    assert_equal 200, last_response.status
    assert_includes last_response.body, 'No movies found'
  end

  def test_index_renders_a_request_button_for_a_requestable_movie
    movie = Movie.create!(title: 'Requestable Card', einthusan_url: 'https://einthusan.tv/movie/req-card')
    Recent.stub(:run, -> { [] }) { get '/' }

    assert_equal 200, last_response.status
    assert_includes last_response.body, '+ Request'
    assert_includes last_response.body, "/movies/#{movie.id}/request"
  end

  def test_index_renders_the_requested_badge_for_a_queued_movie
    Movie.create!(title: 'Queued Card', einthusan_url: 'https://einthusan.tv/movie/queued-card',
                  requested_at: Time.current)
    Recent.stub(:run, -> { [] }) { get '/' }

    assert_equal 200, last_response.status
    assert_includes last_response.body, 'Requested'
  end

  def test_index_renders_the_watch_badge_for_an_attached_movie
    movie = Movie.create!(title: 'Watch Card', einthusan_url: 'https://einthusan.tv/movie/watch-card')
    attach_video(movie)
    Recent.stub(:run, -> { [] }) { get '/' }

    assert_equal 200, last_response.status
    assert_includes last_response.body, 'Watch'
    assert_includes last_response.body, "/streams/#{movie.id}"
  end

  def test_show_renders_the_movie_when_no_video_is_attached
    movie = Movie.create!(title: 'Page Movie', einthusan_url: 'https://einthusan.tv/movie/page')

    get "/movies/#{movie.id}"

    assert_equal 200, last_response.status
    assert_includes last_response.body, 'Page Movie'
    assert_includes last_response.body, 'Request Download'
  end

  def test_show_redirects_to_the_stream_when_a_video_is_attached
    movie = Movie.create!(title: 'Playable', einthusan_url: 'https://einthusan.tv/movie/play')
    attach_video(movie)

    get "/movies/#{movie.id}"

    assert_equal 302, last_response.status
    assert_equal "/streams/#{movie.id}", URI.parse(last_response.headers['Location']).path
  end

  def test_show_returns_404_for_a_missing_movie
    get '/movies/999999'

    assert_equal 404, last_response.status
  end

  def test_request_sets_requested_at_and_redirects_to_the_show_page
    movie = Movie.create!(title: 'Request Me', einthusan_url: 'https://einthusan.tv/movie/request-me')

    post "/movies/#{movie.id}/request"

    assert_equal 302, last_response.status
    assert_equal "/movies/#{movie.id}", URI.parse(last_response.headers['Location']).path
    assert movie.reload.requested_at.present?
  end

  def test_request_is_a_noop_when_a_video_is_already_attached
    movie = Movie.create!(title: 'Already', einthusan_url: 'https://einthusan.tv/movie/already')
    attach_video(movie)

    post "/movies/#{movie.id}/request"

    assert_equal 302, last_response.status
    assert_nil movie.reload.requested_at
  end

  def test_request_returns_404_for_a_missing_movie
    post '/movies/999999/request'

    assert_equal 404, last_response.status
  end

  def test_download_and_status_routes_are_gone
    movie = Movie.create!(title: 'Gone', einthusan_url: 'https://einthusan.tv/movie/gone')

    get "/movies/#{movie.id}/status"
    assert_equal 404, last_response.status

    post "/movies/#{movie.id}/download"
    assert_equal 404, last_response.status
  end
end
