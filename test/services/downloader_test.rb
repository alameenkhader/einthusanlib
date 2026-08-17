require_relative '../test_helper'

class DownloaderTest < Minitest::Test
  VALID_URL = 'https://einthusan.tv/movie/watch/abc/?lang=malayalam'.freeze

  def test_start_rejects_a_non_einthusan_url
    assert_equal :invalid, Downloader.start('https://example.com/movie')
    assert_equal :invalid, Downloader.start('not a url')
  end

  def test_start_is_busy_while_a_download_is_running
    Downloader.instance_variable_set(:@current,
                                     url: VALID_URL, filename: 'movie_1.mp4',
                                     state: :downloading, error: nil, started_at: Time.now)
    Downloader.stub(:run_download, ->(_download) {}) do
      assert_equal :busy, Downloader.start(VALID_URL)
    end
  end

  def test_start_spawns_a_download_and_marks_it_running
    Downloader.stub(:run_download, ->(_download) {}) do
      assert_equal :started, Downloader.start(VALID_URL)
    end

    assert_equal :downloading, Downloader.current[:state]
    assert_equal VALID_URL, Downloader.current[:url]
    assert_match(/\Amovie_\d+\.mp4\z/, Downloader.current[:filename])
  end

  def test_cleanup_library_keeps_only_the_three_newest
    5.times do |i|
      path = File.join(App.movies_dir, "movie_#{i}.mp4")
      File.write(path, 'x')
      File.utime(Time.now + i, Time.now + i, path)
    end

    Downloader.cleanup_library

    remaining = Dir.glob(App.movies_dir.join('*.mp4'))
    assert_equal 3, remaining.length
    assert_includes remaining, File.join(App.movies_dir, 'movie_4.mp4')
    assert_includes remaining, File.join(App.movies_dir, 'movie_3.mp4')
  end

  def test_cleanup_stale_partials_removes_partial_and_control_files
    %w[.part .aria2 .log].each do |ext|
      File.write(File.join(App.downloads_dir, "movie_1.mp4#{ext}"), 'x')
    end

    Downloader.cleanup_stale_partials

    assert_empty Dir.glob(App.downloads_dir.join('movie_1.mp4.{part,aria2,log}'))
  end

  def test_finalize_moves_the_file_into_the_library_and_marks_done
    download = { url: VALID_URL, filename: 'movie_1.mp4', state: :downloading, error: nil, started_at: Time.now }
    File.write(Downloader.download_path('movie_1.mp4'), 'fake video bytes')

    Downloader.send(:finalize, download)

    assert_equal :done, Downloader.current[:state]
    assert_equal 'fake video bytes', File.read(File.join(App.movies_dir, 'movie_1.mp4'))
    refute File.exist?(Downloader.download_path('movie_1.mp4'))
  end

  def test_progress_for_parses_an_aria2_progress_line
    download = { url: VALID_URL, filename: 'movie_1.mp4', state: :downloading, error: nil, started_at: Time.now }
    File.write(Downloader.progress_path('movie_1.mp4'),
               '[#3f9afb 162MiB/1.0GiB(15%) CN:16 DL:396KiB ETA:40m2s]')

    progress = Downloader.progress_for(download)

    assert_equal 15, progress[:percent]
    assert_equal(162 * (1024**2), progress[:downloaded])
    assert_equal((1.0 * (1024**3)).to_i, progress[:total])
    assert_equal(396 * 1024, progress[:dl_bytes_per_sec])
    assert_equal((40 * 60) + 2, progress[:eta_seconds])
  end
end
