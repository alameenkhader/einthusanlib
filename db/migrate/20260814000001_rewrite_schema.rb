class RewriteSchema < ActiveRecord::Migration[8.0]
  def change
    create_table :movies do |t|
      t.string :title, null: false
      t.string :image_url
      t.string :einthusan_url, null: false
      t.timestamp :released_at
      t.string :video_file_name
      t.string :video_content_type
      t.timestamp :video_attached_at

      t.timestamps
    end

    add_index :movies, :einthusan_url, unique: true
    add_index :movies, :released_at
    add_index :movies, :title

    create_table :cache_entries do |t|
      t.string :key, null: false
      t.binary :value
      t.timestamp :expires_at

      t.timestamps
    end

    add_index :cache_entries, :key, unique: true
  end
end
