require 'open3'
require_relative 'config'

def generate_ffmpeg_streaming_urls(list)
  host_ip = '174.66.183.162'  # Replace with your droplet's public IP address
  list.each do |item|
    title = item[:title]
    file_path = item[:file_path]
    file_name = item[:file_name]

    rtmp_url = "rtmp://localhost/live/#{file_name}"
    command = "ffmpeg -re -i #{file_path} -c:v libx264 -f flv #{rtmp_url}"
    puts command
    Open3.popen3(command) do |stdin, stdout, stderr, wait_thr|
      pid = wait_thr.pid
      streaming_url = "http://#{host_ip}:8080/hls/#{file_name}.m3u8"
      item[:streaming_url] = streaming_url
      item[:pid] = pid
      LOGGER.info "Started streaming #{title} at #{streaming_url}. PID: #{pid}"

      # Log stdout and stderr for debugging
      Thread.new do
        stdout.each_line { |line| LOGGER.info "FFmpeg stdout: #{line}" }
      end

      Thread.new do
        stderr.each_line { |line| LOGGER.error "FFmpeg stderr: #{line}" }
      end

      # Ensure the process is running
      exit_status = wait_thr.value
      if exit_status.success?
        LOGGER.info "FFmpeg process for #{title} is running successfully."
      else
        LOGGER.error "FFmpeg process for #{title} failed to start."
      end
    end
  end
end