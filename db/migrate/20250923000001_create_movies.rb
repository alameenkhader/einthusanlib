class CreateMovies < ActiveRecord::Migration[8.0]
  def change
    create_table :movies do |t|
      t.string :title, null: false
      t.string :image_url
      t.string :einthusan_url, null: false
      t.timestamp :released_at

      t.timestamps
    end

    add_index :movies, :einthusan_url, unique: true
    add_index :movies, :released_at
    add_index :movies, :title
  end
end
