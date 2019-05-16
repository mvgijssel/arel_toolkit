lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'arel_toolkit/version'

Gem::Specification.new do |spec|
  spec.name          = 'arel_toolkit'
  spec.version       = ArelToolkit::VERSION
  spec.authors       = ['maarten']
  spec.email         = ['maarten@vgijssel.nl']

  spec.summary       = 'Collection of tools for Arel'
  spec.description   = 'ArelToolkit contains parsing, querying, modifying, optimisations, extensions and more for Arel.'
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

  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.8'

  spec.add_development_dependency 'rubocop', '~> 0.69'
end
