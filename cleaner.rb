# frozen_string_literal: true

require_relative 'config'

DAYS_TO_KEEP = 7

def cutoff_time
  Time.now - (DAYS_TO_KEEP * 24 * 60 * 60)
end

def clean_old_downloads
  LOGGER.info 'Cleaning up old movies'

  Dir.glob("#{DOWNLOAD_PATH}/*").each do |file|
    if File.file?(file) && File.mtime(file) < cutoff_time
      LOGGER.info "Removing old file: #{file}"
      FileUtils.rm(file)
    end
  end
end
