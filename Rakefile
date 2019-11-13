require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'github_changelog_generator/task'

RSpec::Core::RakeTask.new(:spec)

task default: :spec

GitHubChangelogGenerator::RakeTask.new :changelog do |config|
  config.user = 'mvgijssel'
  config.project = 'arel_toolkit'
  config.future_release = "v#{ArelToolkit::VERSION}"
  config.add_pr_wo_labels = false
  config.enhancement_labels = ['enhancement', 'dependencies']
  config.exclude_tags = ['v0.1.0']
end

require 'rake/extensiontask'

task build: :compile

Rake::ExtensionTask.new('pg_result_init') do |ext|
  ext.lib_dir = 'lib/arel_toolkit'
end
