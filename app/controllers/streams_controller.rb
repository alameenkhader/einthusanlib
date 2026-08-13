class StreamsController < ApplicationController
  def show
    @movie = Movie.find(params[:id])

    if @movie.video.attached?
      send_data(
        @movie.video.download,
        type: @movie.video.content_type,
        disposition: "inline",
        stream: true,
        buffer_size: 65536 # 64KB
      )
    else
      head :not_found
    end
  end
end
