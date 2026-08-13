require "test_helper"

class MoviesControllerTest < ActionDispatch::IntegrationTest
  test "index scrapes once per 24h" do
    calls = 0
    Recent.stub(:run, -> { calls += 1; [] }) do
      get movies_path
      get movies_path
    end

    assert_equal 1, calls
  end

  test "index caches the recent movie list" do
    Recent.stub(:run, -> { [] }) { get movies_path }

    assert Rails.cache.read(MoviesController::RECENT_CACHE_KEY).is_a?(Array)
  end

  test "index renders the recent movies from the database" do
    movie = Movie.create!(
      title: "Recent Hit",
      einthusan_url: "https://einthusan.tv/movie/recent",
      image_url: "https://cdn.example.com/recent.jpg",
      released_at: DateTime.new(2020)
    )
    Recent.stub(:run, -> { [] }) { get movies_path }

    assert_response :success
    assert_select "h5", text: "Recent Hit"
    assert_select "img[src=?]", "https://cdn.example.com/recent.jpg"
  end

  test "index with a search term delegates to Search" do
    movie = Movie.create!(
      title: "Matched Movie",
      einthusan_url: "https://einthusan.tv/movie/match",
      released_at: DateTime.new(2020)
    )
    query = nil

    Search.stub(:run, ->(q) { query = q; [ movie ] }) do
      get movies_path, params: { search: "Term" }
    end

    assert_response :success
    assert_equal "Term", query
    assert_select "h5", text: "Matched Movie"
  end

  test "index renders a warning when search finds nothing" do
    Search.stub(:run, ->(_q) { [] }) { get movies_path, params: { search: "Nope" } }

    assert_response :success
    assert_select ".alert", /No movies found/
  end

  test "show renders the movie when no video is attached" do
    movie = Movie.create!(title: "Page Movie", einthusan_url: "https://einthusan.tv/movie/page")

    get movie_path(movie)

    assert_response :success
    assert_select "img[alt=?]", "Page Movie"
    assert_select "#downstream-status"
  end

  test "show redirects to the stream when a video is attached" do
    movie = Movie.create!(title: "Playable", einthusan_url: "https://einthusan.tv/movie/play")
    attach_video(movie)

    get movie_path(movie)

    assert_response :redirect
    assert_redirected_to stream_path(movie)
  end

  test "show returns 404 for a missing movie" do
    get movie_path(999_999)

    assert_response :not_found
  end

  test "download reports conflict while a download is busy" do
    movie = Movie.create!(title: "Busy", einthusan_url: "https://einthusan.tv/movie/busy")
    seen = nil

    Downstream.stub(:run, ->(m) { seen = m; :busy }) do
      post download_movie_path(movie)
    end

    assert_response :conflict
    assert_equal movie, seen
  end

  test "download returns ok when downstream finishes" do
    movie = Movie.create!(title: "Done", einthusan_url: "https://einthusan.tv/movie/done")

    Downstream.stub(:run, ->(_m) { :done }) do
      post download_movie_path(movie)
    end

    assert_response :success
  end

  test "download also accepts the skipped result" do
    movie = Movie.create!(title: "Already", einthusan_url: "https://einthusan.tv/movie/already")

    Downstream.stub(:run, ->(_m) { :skipped }) do
      post download_movie_path(movie)
    end

    assert_response :success
  end

  test "download returns 404 for a missing movie" do
    post download_movie_path(999_999)

    assert_response :not_found
  end
end
