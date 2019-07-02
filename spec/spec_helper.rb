require 'simplecov'
require 'simplecov-console'
SimpleCov.start do
  add_filter %r{^/spec/}
end

require 'bundler/setup'
require 'database_cleaner'
require 'pry'
require 'pry-alias'
require 'arel_toolkit'

require 'postgres_ext' if Gem.loaded_specs.key?('postgres_ext')

require 'support/fake_record'
Arel::Table.engine = FakeRecord::Base.new

require 'support/active_record'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.order = 'random'

  config.alias_it_should_behave_like_to :visit, 'visit:'

  config.expose_dsl_globally = true

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end
end

RSpec::Support::ObjectFormatter.default_instance.max_formatted_output_length = 1000
