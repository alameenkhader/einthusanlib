require "test_helper"

class DownstreamTest < ActiveSupport::TestCase
  def download_path(movie)
    Rails.root.join("tmp", "downloads", "movie_#{movie.id}.mp4").to_s
  end

  def precreate_download(movie)
    FileUtils.mkdir_p(File.dirname(download_path(movie)))
    File.write(download_path(movie), "fake video bytes")
  end

  test "skips when the video is already attached" do
    movie = Movie.create!(title: "Attached", einthusan_url: "https://einthusan.tv/movie/attached")
    attach_video(movie)

    assert_equal :skipped, Downstream.run(movie)
  end

  test "returns busy when the movie is already downstreaming" do
    movie = Movie.create!(title: "Ongoing", einthusan_url: "https://einthusan.tv/movie/ongoing")
    Rails.cache.write(Downstream.new(movie).send(:cache_key), true)

    assert_equal :busy, Downstream.run(movie)
  end

  test "returns busy while another download holds the global lock" do
    movie = Movie.create!(title: "Locked", einthusan_url: "https://einthusan.tv/movie/locked")
    Rails.cache.write(Downstream::GLOBAL_LOCK_KEY, true)

    assert_equal :busy, Downstream.run(movie)
  end

  test "downloads, attaches and cleans up on the happy path" do
    movie = Movie.create!(title: "Happy", einthusan_url: "https://einthusan.tv/movie/happy")
    service = Downstream.new(movie)
    precreate_download(movie)

    result = service.stub(:system, false) { service.run }

    assert_equal :done, result
    assert movie.video.attached?, "expected the downloaded file to be attached"
    refute File.exist?(download_path(movie)), "expected the temp file to be cleaned up"
  end

  test "releases its locks after a successful run" do
    movie = Movie.create!(title: "Clean", einthusan_url: "https://einthusan.tv/movie/clean")
    service = Downstream.new(movie)
    precreate_download(movie)

    service.stub(:system, false) { service.run }

    assert_nil Rails.cache.read(Downstream::GLOBAL_LOCK_KEY)
    assert_nil Rails.cache.read(Downstream.new(movie).send(:cache_key))
  end

  test "fails loudly and releases its locks when the download raises" do
    movie = Movie.create!(title: "Failing", einthusan_url: "https://einthusan.tv/movie/failing")
    service = Downstream.new(movie)

    error = assert_raises(RuntimeError) do
      service.stub(:system, false) do
        service.stub(:download, ->(*) { raise "boom" }) { service.run }
      end
    end
    assert_equal "boom", error.message

    assert_nil Rails.cache.read(Downstream::GLOBAL_LOCK_KEY)
    assert_nil Rails.cache.read(Downstream.new(movie).send(:cache_key))
  end
end
