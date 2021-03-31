# frozen_string_literal: true

require 'simplecov'
SimpleCov.add_filter '/config/'
SimpleCov.add_filter '/spec/'
SimpleCov.start

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
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

  db_adapter = ENV.fetch('ADAPTER', 'sqlite3')
  db_config = YAML.safe_load(File.read('spec/db/database.yml'))

  config.before(:suite) do
    puts "Testing with ActiveRecord #{ActiveRecord::VERSION::STRING}"
    ActiveRecord::Base.establish_connection(db_config[db_adapter])
    require "#{spec_dir}/db/schema"

    require "#{spec_dir}/fixtures/job_classes"
  end

  config.after(:suite) do
    ActiveRecord::Base.connection_pool.disconnect!
  end

  config.before do |example|
    Delayed::Worker.logger.info("Starting example #{example.location}")

    DatabaseCleaner.strategy = example.metadata.fetch(:cleaner_strategy, :transaction)
    DatabaseCleaner.start
  end

  config.after do
    DatabaseCleaner.clean
  end
end
