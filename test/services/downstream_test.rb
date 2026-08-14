require 'test_helper'

class DownstreamTest < Minitest::Test
  def download_path(movie)
    App::ROOT.join('tmp', 'downloads', "movie_#{movie.id}.mp4").to_s
  end

  def precreate_download(movie)
    FileUtils.mkdir_p(File.dirname(download_path(movie)))
    File.write(download_path(movie), 'fake video bytes')
  end

  def test_skips_when_the_video_is_already_attached
    movie = Movie.create!(title: 'Attached', einthusan_url: 'https://einthusan.tv/movie/attached')
    attach_video(movie)

    assert_equal :skipped, Downstream.run(movie)
  end

  def test_does_not_release_locks_when_the_video_is_already_attached
    movie = Movie.create!(title: 'AttachedLocked', einthusan_url: 'https://einthusan.tv/movie/attached-locked')
    attach_video(movie)
    AppCache.write(Downstream::GLOBAL_LOCK_KEY, true)
    AppCache.write(Downstream.new(movie).send(:cache_key), true)

    assert_equal :skipped, Downstream.run(movie)

    assert AppCache.exist?(Downstream::GLOBAL_LOCK_KEY)
    assert AppCache.exist?(Downstream.new(movie).send(:cache_key))
  end

  def test_returns_busy_when_the_movie_is_already_downstreaming
    movie = Movie.create!(title: 'Ongoing', einthusan_url: 'https://einthusan.tv/movie/ongoing')
    AppCache.write(Downstream.new(movie).send(:cache_key), true)

    assert_equal :busy, Downstream.run(movie)
  end

  def test_does_not_release_locks_when_the_movie_is_already_downstreaming
    movie = Movie.create!(title: 'OngoingLocked', einthusan_url: 'https://einthusan.tv/movie/ongoing-locked')
    AppCache.write(Downstream::GLOBAL_LOCK_KEY, true)
    AppCache.write(Downstream.new(movie).send(:cache_key), true)

    assert_equal :busy, Downstream.run(movie)

    assert AppCache.exist?(Downstream::GLOBAL_LOCK_KEY)
    assert AppCache.exist?(Downstream.new(movie).send(:cache_key))
  end

  def test_returns_busy_while_another_download_holds_the_global_lock
    movie = Movie.create!(title: 'Locked', einthusan_url: 'https://einthusan.tv/movie/locked')
    AppCache.write(Downstream::GLOBAL_LOCK_KEY, true)

    assert_equal :busy, Downstream.run(movie)
  end

  def test_does_not_release_the_global_lock_while_another_download_holds_it
    movie = Movie.create!(title: 'LockedGlobal', einthusan_url: 'https://einthusan.tv/movie/locked-global')
    AppCache.write(Downstream::GLOBAL_LOCK_KEY, true)

    assert_equal :busy, Downstream.run(movie)

    assert AppCache.exist?(Downstream::GLOBAL_LOCK_KEY)
  end

  def test_downloads_attaches_and_cleans_up_on_the_happy_path
    movie = Movie.create!(title: 'Happy', einthusan_url: 'https://einthusan.tv/movie/happy')
    service = Downstream.new(movie)
    precreate_download(movie)

    result = service.stub(:system, false) { service.run }

    assert_equal :done, result
    assert movie.video_attached?, 'expected the downloaded file to be attached'
    assert File.exist?(movie.video_path), 'expected the video to live in storage/movies'
    refute File.exist?(download_path(movie)), 'expected the temp file to be moved away'
  end

  def test_releases_its_locks_after_a_successful_run
    movie = Movie.create!(title: 'Clean', einthusan_url: 'https://einthusan.tv/movie/clean')
    service = Downstream.new(movie)
    precreate_download(movie)

    service.stub(:system, false) { service.run }

    assert_nil AppCache.read(Downstream::GLOBAL_LOCK_KEY)
    assert_nil AppCache.read(Downstream.new(movie).send(:cache_key))
  end

  def test_fails_loudly_and_releases_its_locks_when_the_download_raises
    movie = Movie.create!(title: 'Failing', einthusan_url: 'https://einthusan.tv/movie/failing')
    service = Downstream.new(movie)

    error = assert_raises(RuntimeError) do
      service.stub(:system, false) do
        service.stub(:download, ->(*) { raise 'boom' }) { service.run }
      end
    end
    assert_equal 'boom', error.message

    assert_nil AppCache.read(Downstream::GLOBAL_LOCK_KEY)
    assert_nil AppCache.read(Downstream.new(movie).send(:cache_key))
  end
end
