require_relative 'config'

def download_movies(list)
  FileUtils.mkdir_p(DOWNLOAD_PATH)

    list.each do |item|
      url = item[:einthusan_url]
      title = item[:title]
      file_path = item[:file_path]
      if File.exist?(file_path)
        LOGGER.info "File already exists for #{title}, skipping download"
        next
      end

      LOGGER.info "Downloading #{title} from #{url} to #{file_path}"

      command = "youtube-dl -o '#{file_path}' #{url}"
      if system(command)
        puts "Successfully downloaded #{title}"
      else
        puts "Failed to download #{title}"
      end
    end
end
