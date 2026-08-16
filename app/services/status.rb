# Derives the current download state for a movie from the database columns and
# the downloader's progress log. Nothing is cached: each request recomputes it.
class Status
  def self.for(movie)
    case movie.state
    when :watchable
      { state: :watchable, redirect: "/streams/#{movie.id}" }
    when :downloading
      { state: :downloading, progress: Downstream.download_progress(movie) }
    when :requested
      { state: :requested, failed: movie.download_failed_at.present? }
    else
      { state: :requestable }
    end
  end
end
