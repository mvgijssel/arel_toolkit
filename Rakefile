require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'github_changelog_generator/task'

RSpec::Core::RakeTask.new(:spec)

APP_RAKEFILE = File.expand_path('spec/dummy/Rakefile', __dir__)
load 'rails/tasks/engine.rake'

task default: :spec

GitHubChangelogGenerator::RakeTask.new :changelog do |config|
  config.user = 'mvgijssel'
  config.project = 'arel_toolkit'
  config.future_release = "v#{ArelToolkit::VERSION}"
  config.pulls = false
end
