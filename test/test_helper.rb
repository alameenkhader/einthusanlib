ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "minitest/mock"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    # Tests mostly create records via Movie.create! since the scrapers do too.
    fixtures :all

    # Start every test with a clean in-memory cache. Services and controllers
    # share keys like "recent_movies" and "downstreaming_<id>", so this keeps
    # tests isolated and deterministic.
    setup do
      Rails.cache = ActiveSupport::Cache::MemoryStore.new
      Movie.delete_all
      ActiveStorage::Attachment.delete_all
      ActiveStorage::Blob.delete_all
    end

    # Attach a tiny in-memory video to a movie so attached-video code paths
    # (streaming, downstream skip) can run without fixture files on disk.
    def attach_video(movie, content: "fake video bytes", type: "video/mp4")
      blob = ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new(content),
        filename: "movie_#{movie.id}.mp4",
        content_type: type
      )
      movie.video.attach(blob)
    end

    # Builds the minimal Einthusan results-page HTML that the Recent and Search
    # scrapers parse. One movie = one <li>; pass the same movie as a Hash with
    # :title, :year and :slug keys (slug also becomes the image/URL).
    def einthusan_list_html(movies)
      items = movies.map do |movie|
        year = movie[:year] || 1970
        <<~LI
          <li>
            <div class="block1"><img src="//cdn.example.com/#{movie[:slug]}.jpg"></div>
            <div class="block2">
              <a class="title" href="/movie/#{movie[:slug]}"><h3>#{movie[:title]}</h3></a>
              <div class="info"><p>#{year}</p></div>
            </div>
            <div class="block3"><div class="stats"><time datetime="#{year}-05-01"></time></div></div>
          </li>
        LI
      end.join

      <<~HTML
        <div id="UIMovieSummary">
          <ul>
          #{items}
          </ul>
        </div>
      HTML
    end
  end
end
