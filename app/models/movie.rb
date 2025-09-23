class Movie < ApplicationRecord
  validates :title, presence: true
  validates :einthusan_url, presence: true, uniqueness: true

  scope :recent, -> { order(released_at: :desc) }

  has_one_attached :video
  # @message.images.attach(
  #   io: File.open("/path/to/file"),
  #   filename: "file.pdf",
  #   content_type: "application/pdf",
  #   identify: false
  # )
end
