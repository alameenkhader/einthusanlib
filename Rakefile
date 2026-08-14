require_relative 'config/boot'

require 'active_record'
require 'active_record/tasks/database_tasks'
require 'rake/testtask'

ActiveRecord::Tasks::DatabaseTasks.env = App.env
ActiveRecord::Tasks::DatabaseTasks.db_dir = 'db'
ActiveRecord::Tasks::DatabaseTasks.migrations_paths = [ 'db/migrate' ]
ActiveRecord::Tasks::DatabaseTasks.root = App::ROOT.to_s

namespace :db do
  desc 'Create the database'
  task create: :environment do
    ActiveRecord::Tasks::DatabaseTasks.create_all
  end

  desc 'Drop the database'
  task drop: :environment do
    ActiveRecord::Tasks::DatabaseTasks.drop_all
  end

  desc 'Run pending migrations'
  task migrate: :environment do
    ActiveRecord::Tasks::DatabaseTasks.migrate
  end

  desc 'Create, migrate, and prepare the database'
  task prepare: :environment do
    ActiveRecord::Tasks::DatabaseTasks.prepare_all
  end
end

Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.pattern = 'test/**/*_test.rb'
  t.warning = false
end

task default: :test

task :environment do
  require_relative 'config/boot'
end
