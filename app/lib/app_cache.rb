# SQLite-backed cache that mirrors the subset of the Rails.cache API the app
# uses: fetch, read, write (unless_exist/expires_in), exist?, delete.
#
# Values are marshalled into the `cache_entries.value` BLOB column; TTLs are
# enforced lazily (expired entries are purged on access).
class AppCache
  def self.fetch(key, expires_in: nil)
    if (value = read(key))
      return value
    end

    value = yield
    write(key, value, expires_in: expires_in)
    value
  end

  def self.read(key)
    entry = find_entry(key)
    return nil unless entry
    return purge(entry) if expired?(entry)

    # Values are written only by AppCache (Marshal.dump) into our own SQLite
    # database, so the payload is trusted.
    Marshal.load(entry.value) # rubocop:disable Security/MarshalLoad
  end

  def self.write(key, value, unless_exist: false, expires_in: nil)
    entry = find_entry(key)
    return false if unless_exist && entry && !expired?(entry)

    expires_at = expires_in ? Time.current + expires_in.to_i : nil
    if entry
      purge(entry) if expired?(entry)
      entry = find_entry(key)
    end

    if entry
      entry.update!(value: Marshal.dump(value), expires_at: expires_at)
    else
      CacheEntry.create!(key: key, value: Marshal.dump(value), expires_at: expires_at)
    end
    true
  end

  def self.exist?(key)
    entry = find_entry(key)
    return false unless entry

    if expired?(entry)
      purge(entry)
      return false
    end
    true
  end

  def self.delete(key)
    CacheEntry.where(key: key).delete_all
  end

  def self.clear
    CacheEntry.delete_all
  end

  def self.find_entry(key)
    CacheEntry.find_by(key: key)
  end

  def self.expired?(entry)
    entry.expires_at && entry.expires_at <= Time.current
  end

  def self.purge(entry)
    entry.destroy
    nil
  end
end
