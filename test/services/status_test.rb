require 'test_helper'

class StatusTest < Minitest::Test
  def test_watchable_when_a_video_is_attached
    movie = Movie.create!(title: 'Watchable', einthusan_url: 'https://einthusan.tv/movie/watchable')
    attach_video(movie)

    assert_equal :watchable, Status.for(movie)[:state]
  end

  def test_downloading_with_progress_when_a_log_exists
    movie = Movie.create!(title: 'WithProgress', einthusan_url: 'https://einthusan.tv/movie/progress',
                          requested_at: Time.current, download_started_at: Time.current)
    path = Downstream.progress_path(movie)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, "[#a 512MiB/1.5GiB(33%) CN:16 DL:2.3MiB ETA:40m2s]\n")

    status = Status.for(movie)
    assert_equal :downloading, status[:state]
    progress = status[:progress]
    assert_equal 512 * 1024 * 1024, progress[:downloaded]
    assert_equal 33, progress[:percent]
  end

  def test_downloading_without_a_log_does_not_blow_up
    movie = Movie.create!(title: 'NoLog', einthusan_url: 'https://einthusan.tv/movie/no-log',
                          requested_at: Time.current, download_started_at: Time.current)

    status = Status.for(movie)
    assert_equal :downloading, status[:state]
    assert_nil status[:progress]
  end

  def test_requested_when_queued
    movie = Movie.create!(title: 'Queued', einthusan_url: 'https://einthusan.tv/movie/queued',
                          requested_at: Time.current)

    status = Status.for(movie)
    assert_equal :requested, status[:state]
    refute status[:failed]
  end

  def test_requested_marks_will_retry_after_a_failure
    movie = Movie.create!(title: 'Retry', einthusan_url: 'https://einthusan.tv/movie/retry',
                          requested_at: Time.current, download_failed_at: Time.current)

    status = Status.for(movie)
    assert_equal :requested, status[:state]
    assert status[:failed]
  end

  def test_requestable_when_nothing_is_set
    movie = Movie.create!(title: 'Requestable', einthusan_url: 'https://einthusan.tv/movie/requestable')

    assert_equal :requestable, Status.for(movie)[:state]
  end
end
