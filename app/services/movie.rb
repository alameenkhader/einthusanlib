class Movie
  attr_accessor :title, :image_url, :einthusan_url, :released_at

  def initialize(title:, image_url: nil, einthusan_url:, released_at: nil)
    @title = title
    @image_url = image_url
    @einthusan_url = einthusan_url
    @released_at = released_at
  end
end
