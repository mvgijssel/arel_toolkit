require 'simplecov'
require 'simplecov-console'
SimpleCov.formatter = SimpleCov::Formatter::Console
SimpleCov.start

require 'bundler/setup'
require 'pry'
require 'pry-alias'
require 'arel_toolkit'
require 'to_arel'

require 'support/fake_record'
Arel::Table.engine = FakeRecord::Base.new

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.order = 'random'

  config.expose_dsl_globally = true

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
