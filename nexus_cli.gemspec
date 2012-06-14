# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require 'nexus_cli/version'

Gem::Specification.new do |s|
  s.name        = "nexus_cli"
  s.version     = NexusCli.version
  s.authors     = ["Kyle Allan"]
  s.email       = ["kallan@riotgames.com"]
  s.homepage    = ""
  s.summary     = %q{A command-line wrapper for making REST calls to Sonatype Nexus.}
  s.description = s.summary

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  #s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency 'thor'
  s.add_dependency 'rest-client'

  s.add_development_dependency 'rspec'
  s.add_development_dependency 'aruba'
  s.add_development_dependency 'cucumber'
end