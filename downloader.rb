require_relative 'config'

def download_movies(list)
  FileUtils.mkdir_p(DOWNLOAD_PATH)
  list.each do |item|
    url = item[:einthusan_url]
    title = item[:title]
    file_path = item[:file_path]

    next if File.exist?(file_path)

    LOGGER.info "Downloading #{title} from #{url} to #{file_path}"
    system("youtube-dl -o '#{file_path}' #{url}")
  end
end
