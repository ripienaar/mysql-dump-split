# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'mysql_dump_split/version'

Gem::Specification.new do |spec|
  spec.name          = 'mysql_dump_split'
  spec.version       = MysqlDumpSplit::VERSION
  spec.authors       = ['R.I. Pienaar']
  spec.email         = ['rip@devco.net']
  spec.summary       = %q{Splits a MySQL dump into lots of smaller files.}
  spec.description   = %q{It works both with data definitions and data only dumps.}
  spec.homepage      = 'https://github.com/ripienaar/mysql-dump-split'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '>= 1.6'
  spec.add_development_dependency 'rake', '~> 10.0'
end
