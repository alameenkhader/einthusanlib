require 'test_helper'

class MovieTest < Minitest::Test
  def test_is_valid_with_a_title_and_unique_url
    movie = Movie.new(title: 'Valid', einthusan_url: 'https://einthusan.tv/movie/valid')

    assert movie.valid?
  end

  def test_requires_a_title
    movie = Movie.new(einthusan_url: 'https://einthusan.tv/movie/notitle')

    refute movie.valid?
    assert_includes movie.errors[:title], "can't be blank"
  end

  def test_requires_an_einthusan_url
    movie = Movie.new(title: 'No URL')

    refute movie.valid?
    assert_includes movie.errors[:einthusan_url], "can't be blank"
  end

  def test_requires_a_unique_einthusan_url
    Movie.create!(title: 'Original', einthusan_url: 'https://einthusan.tv/movie/dup')
    duplicate = Movie.new(title: 'Copy', einthusan_url: 'https://einthusan.tv/movie/dup')

    refute duplicate.valid?
    assert_includes duplicate.errors[:einthusan_url], 'has already been taken'
  end

  def test_recent_scope_orders_by_released_at_descending
    oldest = Movie.create!(title: 'Oldest', einthusan_url: 'https://einthusan.tv/movie/1', released_at: 10.years.ago)
    newest = Movie.create!(title: 'Newest', einthusan_url: 'https://einthusan.tv/movie/2', released_at: 1.day.ago)

    assert_equal [ newest, oldest ], Movie.recent.to_a
  end

  def test_video_attachment_round_trip
    movie = Movie.create!(title: 'File', einthusan_url: 'https://einthusan.tv/movie/file')
    attach_video(movie)

    assert movie.video_attached?
    assert_equal 'video/mp4', movie.video_content_type
    assert File.exist?(movie.video_path)

    movie.purge_video

    refute movie.video_attached?
    refute File.exist?(movie.video_path)
  end
end
