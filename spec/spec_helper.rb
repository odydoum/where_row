require 'rubygems'
require "bundler/setup"

Bundler.require

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before do
    ActiveRecord::Base.establish_connection adapter: "sqlite3", database: ":memory:"
  end

  config.after do
    ActiveRecord::Base.connection.data_sources.each do |table|
      ActiveRecord::Base.connection.drop_table(table)
    end
  end
end
