# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'object_table/version'

Gem::Specification.new do |spec|
  spec.name          = "object_table"
  spec.version       = ObjectTable::VERSION
  spec.authors       = ["Cheney Lin"]
  spec.email         = ["lincheney@gmail.com"]
  spec.summary       = %q{Simple data table table implementation in ruby}
  spec.description   = spec.summary
  spec.homepage      = "https://github.com/lincheney/ruby-object-table"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '>= 2.0'

  spec.add_runtime_dependency 'narray', "~> 0.6.1"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency 'rspec', "~> 3.1"
  spec.add_development_dependency 'coveralls', ">= 0.7"
end

