require "test_helper"
require "minitest/mock"

class MoviesControllerTest < ActionDispatch::IntegrationTest
  setup do
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
  end

  test "index scrapes once per 24h" do
    calls = 0
    Recent.stub(:run, -> { calls += 1; [] }) do
      get movies_path
      get movies_path
    end

    assert_equal 1, calls
  end

  test "index caches the recent movie list" do
    Recent.stub(:run, -> { [] }) { get movies_path }

    assert Rails.cache.read(MoviesController::RECENT_CACHE_KEY).is_a?(Array)
  end
end
