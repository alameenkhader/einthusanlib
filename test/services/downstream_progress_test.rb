require 'test_helper'

class DownstreamProgressTest < Minitest::Test
  def write_log(movie, contents)
    path = Downstream.progress_path(movie)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, contents)
  end

  def test_returns_nil_when_no_progress_log_exists
    movie = Movie.create!(title: 'NoLog', einthusan_url: 'https://einthusan.tv/movie/no-log')

    assert_nil Downstream.download_progress(movie)
  end

  def test_parses_aria2c_progress_lines
    movie = Movie.create!(title: 'Aria', einthusan_url: 'https://einthusan.tv/movie/aria')
    write_log(movie, <<~LOG)
      [Einthusan] 61SE: Downloading webpage
      [#ed498a 8.5MiB/1.5GiB(0%) CN:16 DL:272KiB ETA:1h38m37s]
      [#ed498a 512MiB/1.5GiB(33%) CN:16 DL:15MiB ETA:1m]
    LOG

    progress = Downstream.download_progress(movie)
    assert_equal 512 * 1024 * 1024, progress[:downloaded]
    assert_equal (1.5 * 1024 * 1024 * 1024).to_i, progress[:total]
    assert_equal 33, progress[:percent]
    assert_equal 15 * 1024 * 1024, progress[:dl_bytes_per_sec]
    assert_equal 60, progress[:eta_seconds]
  end

  def test_parses_various_eta_formats
    cases = {
      '2h16s' => (2 * 3600) + 16,
      '40m2s' => (40 * 60) + 2,
      '1m' => 60,
      '0s' => 0
    }
    cases.each do |eta, expected|
      movie = Movie.create!(title: "Eta#{eta}", einthusan_url: "https://einthusan.tv/movie/eta-#{eta}")
      write_log(movie, "[#a 1MiB/1.5GiB(0%) CN:16 DL:1KiB ETA:#{eta}]\n")
      assert_equal expected, Downstream.download_progress(movie)[:eta_seconds]
    end

    movie = Movie.create!(title: 'EtaUnk', einthusan_url: 'https://einthusan.tv/movie/eta-unk')
    write_log(movie, "[#d 4MiB/1.5GiB(0%) CN:16 DL:1KiB ETA:Unk]\n")
    assert_nil Downstream.download_progress(movie)[:eta_seconds]
  end

  def test_uses_the_most_recent_progress_line
    movie = Movie.create!(title: 'Recent', einthusan_url: 'https://einthusan.tv/movie/recent')
    write_log(movie, <<~LOG)
      [#a 2MiB/1.5GiB(0%)]
      [#a 300MiB/1.5GiB(20%)]
      [#a 1.2GiB/1.5GiB(80%)]
    LOG

    progress = Downstream.download_progress(movie)
    assert_equal (1.2 * 1024 * 1024 * 1024).to_i, progress[:downloaded]
    assert_equal 80, progress[:percent]
  end

  def test_parses_youtube_dl_fallback_progress_lines
    movie = Movie.create!(title: 'Plain', einthusan_url: 'https://einthusan.tv/movie/plain')
    write_log(movie, "[download]  45.3MiB/1.50GiB (3%)\n")

    progress = Downstream.download_progress(movie)
    assert_equal (45.3 * 1024 * 1024).to_i, progress[:downloaded]
    assert_equal 3, progress[:percent]
    assert_nil progress[:dl_bytes_per_sec]
    assert_nil progress[:eta_seconds]
  end

  def test_returns_nil_when_the_log_has_no_progress
    movie = Movie.create!(title: 'Garbage', einthusan_url: 'https://einthusan.tv/movie/garbage')
    write_log(movie, "no progress here\n")

    assert_nil Downstream.download_progress(movie)
  end
end
