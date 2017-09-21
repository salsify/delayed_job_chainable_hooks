require 'simplecov'
SimpleCov.add_filter '/config/'
SimpleCov.add_filter '/spec/'
SimpleCov.start

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'delayed_job_chainable_hooks'

require 'database_cleaner'

spec_dir = File.dirname(__FILE__)

FileUtils.makedirs('log')

Delayed::Worker.read_ahead = 1
Delayed::Worker.destroy_failed_jobs = false

Delayed::Worker.logger = Logger.new('log/test.log')
Delayed::Worker.logger.level = Logger::DEBUG
ActiveRecord::Base.logger = Delayed::Worker.logger
ActiveRecord::Migration.verbose = false

RSpec.configure do |config|
  config.order = 'random'

  # Allows RSpec to persist some state between runs in order to support
  # the `--only-failures` and `--next-failure` CLI options. We recommend
  # you configure your source control system to ignore this file.
  config.example_status_persistence_file_path = 'spec/examples.txt'

  DATABASE_NAME = 'delayed_job_chainable_hooks_test'.freeze

  config.before(:suite) do
    `createdb #{DATABASE_NAME}`
    database_url = "postgres://localhost/#{DATABASE_NAME}"
    ActiveRecord::Base.establish_connection(database_url)

    require "#{spec_dir}/db/schema"
  end

  config.after(:suite) do
    ActiveRecord::Base.connection_pool.disconnect!
    `dropdb --if-exists #{DATABASE_NAME}`
  end

  config.before(:each) do |example|
    Delayed::Worker.logger.info("Starting example #{example.location}")

    DatabaseCleaner.strategy = example.metadata.fetch(:cleaner_strategy, :transaction)
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end
