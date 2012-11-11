require 'rubygems'
require 'bundler'
require 'spork'

Spork.prefork do
  require 'webmock/rspec'

  APP_ROOT = File.expand_path('../../', __FILE__)
  ENV["NEXUS_CONFIG"] = File.join(APP_ROOT, "spec", "fixtures", "nexus.config")
end

Spork.each_run do
  require 'nexus_cli'
end
