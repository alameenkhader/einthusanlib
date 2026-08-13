require "test_helper"

class StreamsControllerTest < ActionDispatch::IntegrationTest
  test "show streams the attached video inline" do
    movie = Movie.create!(title: "Streamy", einthusan_url: "https://einthusan.tv/movie/stream")
    attach_video(movie)

    get stream_path(movie)

    assert_response :success
    assert_equal "video/mp4", response.content_type
    assert_equal "fake video bytes", response.body
    assert_includes response.get_header("Content-Disposition"), "inline"
  end

  test "show returns 404 when the movie has no video" do
    movie = Movie.create!(title: "Bare", einthusan_url: "https://einthusan.tv/movie/bare")

    get stream_path(movie)

    assert_response :not_found
  end

  test "show returns 404 for a missing movie" do
    get stream_path(999_999)

    assert_response :not_found
  end
end
