class Movie < ApplicationRecord
  validates :title, presence: true
  validates :einthusan_url, presence: true, uniqueness: true

  scope :recent, -> { order(released_at: :desc) }

  def video_attached?
    video_file_name.present?
  end

  def video_path
    App::ROOT.join('storage', 'movies', "#{id}.mp4").to_s
  end

  def attach_video_file(source_path, content_type:)
    FileUtils.mkdir_p(File.dirname(video_path))
    FileUtils.mv(source_path, video_path)
    update!(
      video_file_name: "movie_#{id}.mp4",
      video_content_type: content_type,
      video_attached_at: Time.current
    )
  end

  def purge_video
    FileUtils.rm_f(video_path)
    update!(video_file_name: nil, video_content_type: nil, video_attached_at: nil)
  end
end
