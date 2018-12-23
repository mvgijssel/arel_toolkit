lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'to_arel/version'

Gem::Specification.new do |spec|
  spec.name          = 'to_arel'
  spec.version       = ToArel::VERSION
  spec.authors       = ['maarten']
  spec.email         = ['maarten@vgijssel.nl']

  spec.summary       = 'Convert SQL to an Arel ast'
  spec.description   = 'Covert SQL back to an AST so you can modifications to the AST.'
  spec.homepage      = 'https://github.com/mvgijssel/to_arel'
  spec.license       = 'MIT'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'arel', '~> 9.0.0'
  spec.add_dependency 'pg_query', '~> 1.1.0'

  spec.add_development_dependency 'bundler', '~> 1.17'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.2'
  spec.add_development_dependency 'guard', '~> 2.15.0'
  spec.add_development_dependency 'guard-rspec', '~> 4.7.3'
  spec.add_development_dependency 'rubocop', '~> 0.61.1'
  spec.add_development_dependency 'flog', '~> 4.6.2'
  spec.add_development_dependency 'simplecov', '~> 0.16.1'

  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'pry-nav'
  spec.add_development_dependency 'pry-stack_explorer'
  spec.add_development_dependency 'pry-alias'
end
