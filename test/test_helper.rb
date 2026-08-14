ENV['RACK_ENV'] = 'test'
ENV['SECRET_KEY_BASE'] ||= 'test-secret-for-sessions-test-secret-for-sessions-test-secret-for-sessions-test'

require_relative '../config/boot'
require_relative '../app'

require 'minitest/autorun'
require 'minitest/mock'
require 'rack/test'

class Minitest::Test
  include Rack::Test::Methods

  def app
    Chalaflix
  end

  def setup
    Movie.delete_all
    CacheEntry.delete_all
    FileUtils.rm_rf(App::ROOT.join('storage', 'movies'))
    FileUtils.mkdir_p(App::ROOT.join('storage', 'movies'))
    FileUtils.rm_rf(App::ROOT.join('tmp', 'downloads'))
    FileUtils.mkdir_p(App::ROOT.join('tmp', 'downloads'))
  end

  # Attach a tiny video to a movie so attached-video code paths (streaming,
  # downstream skip) can run without fixture files on disk.
  def attach_video(movie, content: 'fake video bytes', type: 'video/mp4')
    path = App::ROOT.join('tmp', 'downloads', "movie_#{movie.id}.mp4")
    FileUtils.mkdir_p(path.dirname)
    File.write(path, content)
    movie.attach_video_file(path, content_type: type)
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
