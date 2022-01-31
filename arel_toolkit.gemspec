lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'arel_toolkit/version'

Gem::Specification.new do |spec|
  spec.name          = 'arel_toolkit'
  spec.version       = ArelToolkit::VERSION
  spec.authors       = ['maarten']
  spec.email         = ['maarten@vgijssel.nl']

  spec.summary       = 'Collection of tools for Arel'
  spec.description   = <<~STRING
    ArelToolkit contains parsing, querying, modifying, optimisations, extensions and more for Arel.
  STRING
  spec.homepage      = 'https://github.com/mvgijssel/arel_toolkit'
  spec.license       = 'MIT'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
  spec.extensions    = ['ext/pg_result_init/extconf.rb']

  spec.add_dependency 'activerecord', '>= 5.0.0'
  spec.add_dependency 'pg', '~> 1.1.4'
  spec.add_dependency 'pg_query', '~> 2.1'

  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'dpl', '~> 1.10.11'
  spec.add_development_dependency 'github_changelog_generator', '~> 1.15'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rake-compiler', '~> 1.0'
  spec.add_development_dependency 'rspec', '~> 3.8'
  spec.add_development_dependency 'approvals', '~> 0.0.24'
  spec.add_development_dependency 'appraisal', '~> 2.4.1'
  spec.add_development_dependency 'database_cleaner', '~> 1.7.0'
  spec.add_development_dependency 'simplecov', '~> 0.16.1'
  spec.add_development_dependency 'simplecov-console', '~> 0.4.2'

  # When updating also update .codeclimate.yml:5
  spec.add_development_dependency 'rubocop', '= 0.71.0'
  spec.add_development_dependency 'guard', '~> 2.15'
  spec.add_development_dependency 'guard-rspec', '~> 4.7'
  spec.add_development_dependency 'guard-rubocop', '~> 1.3.0'
  spec.add_development_dependency 'guard-rake', '~> 1.0.0'
  spec.add_development_dependency 'stackprof', '~> 0.2'
  spec.add_development_dependency 'memory_profiler', '~> 0.9'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'pry-nav'
  spec.add_development_dependency 'pry-doc'
  spec.add_development_dependency 'pry-rescue'
  spec.add_development_dependency 'pry-stack_explorer'
  spec.add_development_dependency 'pry-alias'
end
