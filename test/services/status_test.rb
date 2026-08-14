require 'test_helper'

class StatusTest < Minitest::Test
  # rubocop:disable Metrics/AbcSize
  def test_includes_progress_when_a_progress_log_exists
    movie = Movie.create!(title: 'WithProgress', einthusan_url: 'https://einthusan.tv/movie/progress')
    AppCache.write(Downstream.status_key(movie), { state: 'working', message: 'Downloading...' })
    path = Downstream.progress_path(movie)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, "[#a 512MiB/1.5GiB(33%) CN:16 DL:2.3MiB ETA:40m2s]\n")

    status = Status.for(movie)
    assert_equal 'working', status[:state]
    assert_equal 512 * 1024 * 1024, status[:downloaded]
    assert_equal (1.5 * 1024 * 1024 * 1024).to_i, status[:total]
    assert_equal 33, status[:percent]
    assert_equal (2.3 * 1024 * 1024).to_i, status[:dl_bytes_per_sec]
    assert_equal (40 * 60) + 2, status[:eta_seconds]
  end
  # rubocop:enable Metrics/AbcSize

  def test_returns_idle_without_progress_keys
    movie = Movie.create!(title: 'Idle', einthusan_url: 'https://einthusan.tv/movie/idle')

    status = Status.for(movie)
    assert_equal 'idle', status[:state]
    refute status.key?(:downloaded)
  end
end
