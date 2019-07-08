source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

gem 'sorbet'
gem 'sorbet-runtime'

# Specify your gem's dependencies in arel_toolkit.gemspec
gemspec
