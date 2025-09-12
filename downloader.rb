require_relative 'config'
require 'pathname'

def get_available_space(path)
  df_output = `df -k "#{path}" 2>/dev/null`
  return 0 unless $?.success?

  available_kb = df_output.split("\n")[1].split(/\s+/)[3].to_i
  available_kb.to_f / 1024  # Convert to MB
end

def clean_partial_downloads
  Dir.glob(File.join(DOWNLOAD_PATH, "*.part")).each do |part_file|
    LOGGER.info "Cleaning up partial download: #{part_file}"
    File.delete(part_file)
  end
end

def download_movies(list)
  FileUtils.mkdir_p(DOWNLOAD_PATH)

  clean_partial_downloads

  list.each do |item|
    url = item[:einthusan_url]
    title = item[:title]
    file_path = item[:file_path]

    # Check available disk space
    available_mb = get_available_space(DOWNLOAD_PATH)

    if available_mb < 1500
      LOGGER.info "Insufficient disk space. Only #{available_mb.round(2)}MB available."
      return list
    end

    if File.exist?(file_path)
      LOGGER.info "File already exists: #{file_path}. Skipping download."
      item[:status] = :downloaded
      next
    end

    LOGGER.info "Downloading #{title} from #{url} to #{file_path}"
    system("youtube-dl -o '#{file_path}' #{url}")
    item[:status] = :downloaded
  end

  list.select { |item| item[:status] == :downloaded }
end
