# Byte/rate/ETA formatting for the download progress UI (shared by index and
# show views). Mirrors the helpers that lived in the old polling JavaScript.
module Formatting
  def format_bytes(bytes)
    return '0 B' if bytes.nil? || bytes.negative?

    units = %w[B KiB MiB GiB TiB]
    value = bytes.to_f
    index = 0
    while value >= 1024 && index < units.length - 1
      value /= 1024
      index += 1
    end
    format(index.zero? ? '%.0f %s' : '%.1f %s', value, units[index])
  end

  def format_eta(seconds)
    return nil if seconds.nil? || seconds.negative?

    h = (seconds / 3600).floor
    m = ((seconds % 3600) / 60).floor
    if h.positive?
      m.positive? ? "~#{h}h #{m}m" : "~#{h}h"
    elsif m.positive?
      "~#{m}m"
    else
      "~#{seconds.ceil}s"
    end
  end

  def format_rate(bytes_per_sec)
    return nil if bytes_per_sec.nil? || bytes_per_sec.negative?

    units = %w[B KiB MiB GiB TiB]
    value = bytes_per_sec.to_f
    index = 0
    while value >= 1024 && index < units.length - 1
      value /= 1024
      index += 1
    end
    format(value >= 100 ? '%.0f %s/s' : '%.1f %s/s', value, units[index])
  end

  def format_progress(progress)
    return 'Downloading...' if progress.nil? || !progress[:total].to_i.positive?

    text = "#{format_bytes(progress[:downloaded])} of #{format_bytes(progress[:total])}"
    if (eta = format_eta(progress[:eta_seconds]))
      text += " — #{eta} left"
    end
    if (rate = format_rate(progress[:dl_bytes_per_sec]))
      text += " @ #{rate}"
    end
    text
  end
end
