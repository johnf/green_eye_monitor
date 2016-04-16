# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'green_eye_monitor/version'

Gem::Specification.new do |spec|
  spec.name          = 'green_eye_monitor'
  spec.version       = GreenEyeMonitor::VERSION
  spec.authors       = ['John Ferlito']
  spec.email         = ['johnf@inodes.org']

  spec.summary       = 'Library to speak to Brultech GEM energy consumption monitor over a serial port'
  spec.homepage      = 'https://github.com/johnf/green_eye_monitor'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.require_paths = ['lib']
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }

  spec.add_dependency 'serialport'
  spec.add_dependency 'bindata'
  spec.add_dependency 'slop'
  spec.add_dependency 'awesome_print'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'rubocop-rspec'
  spec.add_development_dependency 'rspec_junit_formatter'
  spec.add_development_dependency 'coveralls'
end
