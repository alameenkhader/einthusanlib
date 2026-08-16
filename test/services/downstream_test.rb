require 'test_helper'

class DownstreamTest < Minitest::Test
  def download_path(movie)
    App::ROOT.join('tmp', 'downloads', "movie_#{movie.id}.mp4").to_s
  end

  def precreate_download(movie)
    FileUtils.mkdir_p(File.dirname(download_path(movie)))
    File.write(download_path(movie), 'fake video bytes')
  end

  # Runs Downstream.process_one with the downloader's system calls stubbed to
  # false so make_storage_space is a no-op and pre-created files are attached
  # instead of re-downloaded.
  def process_one_with(service)
    service.stub(:system, false) do
      Downstream.stub(:new, ->(_movie) { service }) { Downstream.process_one }
    end
  end

  def test_process_one_returns_nil_when_the_queue_is_empty
    assert_nil Downstream.process_one
  end

  def test_process_one_downloads_the_oldest_new_request
    older = Movie.create!(title: 'Older', einthusan_url: 'https://einthusan.tv/movie/older',
                          requested_at: Time.current - 60)
    newer = Movie.create!(title: 'Newer', einthusan_url: 'https://einthusan.tv/movie/newer',
                          requested_at: Time.current)
    precreate_download(older)

    result = process_one_with(Downstream.new(older))

    assert_equal :done, result
    older.reload
    newer.reload
    assert older.video_attached?, 'expected the older request to be downloaded first'
    assert_nil newer.download_started_at
  end

  def test_process_one_marks_the_movie_failed_when_the_download_raises
    movie = Movie.create!(title: 'Failing', einthusan_url: 'https://einthusan.tv/movie/failing',
                          requested_at: Time.current)
    service = Downstream.new(movie)
    service.stub(:download, ->(*) { raise 'boom' }) do
      Downstream.stub(:new, ->(_m) { service }) { Downstream.process_one }
    end

    movie.reload
    assert_nil movie.download_started_at
    assert movie.download_failed_at.present?
  end

  def test_pending_puts_new_requests_ahead_of_failed_retries
    failed_old = Movie.create!(title: 'FailedOld', einthusan_url: 'https://einthusan.tv/movie/failed-old',
                               requested_at: Time.current - 120, download_failed_at: Time.current - 60)
    new_recent = Movie.create!(title: 'NewRecent', einthusan_url: 'https://einthusan.tv/movie/new-recent',
                               requested_at: Time.current - 60)

    assert_equal [ new_recent, failed_old ], Downstream.pending.to_a
  end

  def test_pending_excludes_attached_downloading_and_unrequested_movies
    attached = Movie.create!(title: 'Attached', einthusan_url: 'https://einthusan.tv/movie/a')
    attach_video(attached)
    Movie.create!(title: 'Downloading', einthusan_url: 'https://einthusan.tv/movie/d',
                  requested_at: Time.current, download_started_at: Time.current)
    Movie.create!(title: 'Unrequested', einthusan_url: 'https://einthusan.tv/movie/u')
    queued = Movie.create!(title: 'Queued', einthusan_url: 'https://einthusan.tv/movie/q',
                           requested_at: Time.current)

    assert_equal [ queued ], Downstream.pending.to_a
  end

  def test_clear_stale_downloads_frees_crashed_runs
    stale = Movie.create!(title: 'Stale', einthusan_url: 'https://einthusan.tv/movie/stale',
                          requested_at: Time.current - 10.hours, download_started_at: Time.current - 7.hours)
    fresh = Movie.create!(title: 'Fresh', einthusan_url: 'https://einthusan.tv/movie/fresh',
                          requested_at: Time.current, download_started_at: Time.current)

    Downstream.clear_stale_downloads

    stale.reload
    fresh.reload
    assert_nil stale.download_started_at
    assert stale.download_failed_at.present?
    assert fresh.download_started_at.present?
  end

  def test_run_skips_when_the_video_is_already_attached
    movie = Movie.create!(title: 'Attached', einthusan_url: 'https://einthusan.tv/movie/attached')
    attach_video(movie)

    assert_equal :skipped, Downstream.new(movie).run
  end

  def test_cleanup_stale_partials_removes_control_and_log_files_but_keeps_bare_mp4
    movie = Movie.create!(title: 'Cleanup', einthusan_url: 'https://einthusan.tv/movie/cleanup')
    dir = App::ROOT.join('tmp', 'downloads')
    FileUtils.mkdir_p(dir)
    bare = dir.join("movie_#{movie.id}.mp4")
    partials = %w[.part .aria2 .log].map { |ext| dir.join("movie_#{movie.id}.mp4#{ext}") }
    (partials + [ bare ]).each { |path| File.write(path, 'x') }

    Downstream.new(movie).send(:cleanup_stale_partials)

    assert File.exist?(bare), 'expected the bare .mp4 to be salvaged'
    partials.each { |path| refute File.exist?(path), "expected #{File.basename(path)} to be removed" }
  end
end
