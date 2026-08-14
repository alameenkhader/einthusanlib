# Reads the current download status for a movie so the front-end can poll it.
class Status
  def self.for(movie)
    entry = AppCache.read(Downstream.status_key(movie))
    status = entry || { state: 'idle', message: 'Waiting to downstream...' }
    status[:redirect] = "/streams/#{movie.id}" if movie.video_attached?
    if (progress = Downstream.download_progress(movie))
      status[:downloaded] = progress[:downloaded]
      status[:total] = progress[:total]
      status[:percent] = progress[:percent]
      status[:dl_bytes_per_sec] = progress[:dl_bytes_per_sec]
      status[:eta_seconds] = progress[:eta_seconds]
    end
    status
  end
end
