# Load the Rails application.
require_relative 'application'

load File.expand_path('../../../lib/arel_toolkit.rb', __dir__)

# Initialize the Rails application.
Rails.application.initialize!
