class Movie < ApplicationRecord
  validates :title, presence: true
  validates :einthusan_url, presence: true, uniqueness: true

  scope :recent, -> { order(released_at: :desc) }
end
