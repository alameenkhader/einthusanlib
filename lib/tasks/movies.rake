namespace :movies do
  desc "Fetch recent movies from Einthusan"
  # This task is designed to run periodically with a cronjob
  # to automatically fetch and update the movie database
  task fetch_recent: :environment do
    Recent.run
  end
end
