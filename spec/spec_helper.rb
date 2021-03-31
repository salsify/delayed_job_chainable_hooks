# frozen_string_literal: true

require 'pg'
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

  database_name = 'delayed_job_chainable_hooks_test'
  database_host = ENV.fetch('PGHOST', 'localhost')
  database_port = ENV.fetch('PGPORT', 5432)
  database_user = ENV.fetch('PGUSER', 'postgres')
  database_pass = ENV.fetch('PGPASS', 'password')
  admin_database_url = "postgres://#{database_user}:#{database_pass}@#{database_host}:#{database_port}"
  database_url = "#{admin_database_url}/#{database_name}"

  config.before(:suite) do
    PG::Connection.open(admin_database_url) do |c|
      puts "DROP DATABASE IF EXISTS #{database_name}"
      c.exec("DROP DATABASE IF EXISTS #{database_name}")
      c.exec("CREATE DATABASE #{database_name}")
      pg_version = c.exec('SELECT version()')

      puts "Testing with Postgres version: #{pg_version.getvalue(0, 0)}"
      puts "Testing with ActiveRecord #{ActiveRecord::VERSION::STRING}"
    end
    ActiveRecord::Base.establish_connection(database_url)

    require "#{spec_dir}/db/schema"

    require "#{spec_dir}/fixtures/job_classes"
  end

  config.after(:suite) do
    ActiveRecord::Base.connection_pool.disconnect!
    PG::Connection.open(admin_database_url) do |c|
      c.exec("DROP DATABASE #{database_name}")
    end
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
