lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'md2conf/version'

Gem::Specification.new do |spec|
  spec.name          = 'md2conf'
  spec.version       = Md2conf::VERSION
  spec.authors       = ['Eugene Piven', 'Vladimir Tyshkevich']
  spec.email         = ['epiven@gmail.com']
  spec.summary       = 'Convert Markdown to Confluence XHTML storage format'
  spec.homepage      = 'https://github.com/pegasd/md2conf'
  spec.license       = 'MIT'
  spec.files         = Dir['README.md', 'CHANGELOG.md', 'lib/**/*.rb']
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rubocop'

  spec.add_runtime_dependency 'redcarpet', '~> 2.0'
end
