require "test_helper"

class MovieTest < ActiveSupport::TestCase
  test "is valid with a title and unique url" do
    movie = Movie.new(title: "Valid", einthusan_url: "https://einthusan.tv/movie/valid")

    assert movie.valid?
  end

  test "requires a title" do
    movie = Movie.new(einthusan_url: "https://einthusan.tv/movie/notitle")

    refute movie.valid?
    assert_includes movie.errors[:title], "can't be blank"
  end

  test "requires an einthusan url" do
    movie = Movie.new(title: "No URL")

    refute movie.valid?
    assert_includes movie.errors[:einthusan_url], "can't be blank"
  end

  test "requires a unique einthusan url" do
    Movie.create!(title: "Original", einthusan_url: "https://einthusan.tv/movie/dup")
    duplicate = Movie.new(title: "Copy", einthusan_url: "https://einthusan.tv/movie/dup")

    refute duplicate.valid?
    assert_includes duplicate.errors[:einthusan_url], "has already been taken"
  end

  test "recent scope orders by released_at descending" do
    oldest = Movie.create!(title: "Oldest", einthusan_url: "https://einthusan.tv/movie/1", released_at: 10.years.ago)
    newest = Movie.create!(title: "Newest", einthusan_url: "https://einthusan.tv/movie/2", released_at: 1.day.ago)

    assert_equal [ newest, oldest ], Movie.recent.to_a
  end
end
