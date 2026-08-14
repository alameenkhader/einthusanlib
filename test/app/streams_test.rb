require 'test_helper'

class StreamsTest < Minitest::Test
  def test_show_streams_the_attached_video_inline
    movie = Movie.create!(title: 'Streamy', einthusan_url: 'https://einthusan.tv/movie/stream')
    attach_video(movie)

    get "/streams/#{movie.id}"

    assert_equal 200, last_response.status
    assert_equal 'video/mp4', last_response.content_type
    assert_equal 'fake video bytes', last_response.body
    assert_includes last_response.headers['Content-Disposition'], 'inline'
  end

  def test_show_returns_404_when_the_movie_has_no_video
    movie = Movie.create!(title: 'Bare', einthusan_url: 'https://einthusan.tv/movie/bare')

    get "/streams/#{movie.id}"

    assert_equal 404, last_response.status
  end

  def test_show_returns_404_for_a_missing_movie
    get '/streams/999999'

    assert_equal 404, last_response.status
  end
end
