# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'pruby/version'

Gem::Specification.new do |spec|
  spec.name          = 'pruby'
  spec.version       = PRuby::VERSION
  spec.platform      = Gem::Platform::RUBY
  spec.authors       = ['Guy Tremblay']
  spec.email         = ['tremblay.guy@uqam.ca']
  spec.summary       = 'Un gem pour du parallelisme simple en Ruby.'
  spec.description   = 'Un gem pour du parallelisme simple en Ruby.'
  spec.homepage      = 'http://www.labunix.uqam.ca/~tremblay/INF5171/pruby'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
    .reject { |f| f =~ /Programmes\// }
    .reject { |f| f =~ /essais\// }
    .reject { |f| f =~ /WIP/ }
    .reject { |f| f =~ /IDEES.txt/ }
    .reject { |f| f =~ /A-FAIRE/ }
    .reject { |f| f =~ /TEMPS/ }
    .reject { |f| f =~ /installation-ruby.txt/ }
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.7'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'minitest'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'flay'
  spec.add_development_dependency 'flog'
  spec.add_development_dependency 'reek' unless ENV['HOST'] =~ /japet|c34581/
  spec.add_development_dependency 'yard'

  spec.add_runtime_dependency 'forkjoin'
  spec.add_runtime_dependency 'system'
  spec.add_runtime_dependency 'ruby-processing'
end
