# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require 'nexus_cli/version'

Gem::Specification.new do |s|
  s.name        = "nexus_cli"
  s.version     = NexusCli::VERSION
  s.authors     = ["Kyle Allan"]
  s.email       = ["kallan@riotgames.com"]
  s.homepage    = "https://github.com/RiotGames/nexus_cli"
  s.summary     = %q{A command-line wrapper for making REST calls to Sonatype Nexus.}
  s.description = s.summary

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency 'thor'
  s.add_dependency 'extlib'
  s.add_dependency 'json'
  s.add_dependency 'highline'
  s.add_dependency 'jsonpath'
  s.add_runtime_dependency 'celluloid', '~> 0.14.0'
  s.add_runtime_dependency 'faraday', '>= 0.8.4'
  s.add_runtime_dependency 'faraday', '>= 0.8.4'
  s.add_runtime_dependency 'faraday_middleware', '>= 0.9.0'
  s.add_runtime_dependency 'net-http-persistent', '>= 2.8'
  s.add_runtime_dependency 'addressable', '~> 2.3.4'
  s.add_runtime_dependency 'buff-config'
  s.add_runtime_dependency 'activesupport', '>= 3.2.0'

  s.add_development_dependency 'rspec'
  s.add_development_dependency 'aruba'
  s.add_development_dependency 'cucumber'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'webmock'
end