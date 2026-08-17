require_relative '../test_helper'

class AppTest < Minitest::Test
  def test_index_renders_the_paste_form
    get '/'

    assert last_response.ok?
    assert_includes last_response.body, 'Paste an einthusan.tv movie URL'
  end

  def test_post_downloads_starts_and_redirects_home
    Downloader.stub(:start, :started) do
      post '/downloads', url: 'https://einthusan.tv/movie/watch/abc/?lang=malayalam'
    end

    assert last_response.redirect?
    assert_equal '/', URI.parse(last_response['Location']).path
  end

  def test_post_downloads_notices_when_busy
    Downloader.stub(:start, :busy) do
      post '/downloads', url: 'https://einthusan.tv/movie/watch/abc/?lang=malayalam'
    end

    assert last_response.redirect?
    assert_includes last_response['Location'], 'notice='
  end

  def test_status_json_reports_idle_when_nothing_is_downloading
    get '/status.json'

    assert last_response.ok?
    body = JSON.parse(last_response.body)
    assert_equal 'idle', body['state']
  end

  def test_watch_serves_a_completed_movie
    File.write(File.join(App.movies_dir, 'movie_1.mp4'), 'fake video bytes')

    get '/watch/movie_1.mp4'

    assert last_response.ok?
    assert_equal 'fake video bytes', last_response.body
  end

  def test_watch_rejects_unknown_or_unsafe_names
    get '/watch/nope.mp4'
    assert_equal 404, last_response.status

    get '/watch/..%2Fsecret.mp4'
    assert_equal 404, last_response.status
  end
end
