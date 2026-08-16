class AddDownloadRequestFields < ActiveRecord::Migration[8.0]
  def change
    change_table :movies do |t|
      t.timestamp :requested_at
      t.timestamp :download_started_at
      t.timestamp :download_failed_at
    end

    add_index :movies, :requested_at
  end
end
