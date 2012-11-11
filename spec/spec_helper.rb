APP_ROOT = File.expand_path('../../', __FILE__)

ENV["NEXUS_CONFIG"] = File.join(APP_ROOT, "spec", "fixtures", "nexus.config")

require 'nexus_cli'
require 'webmock/rspec'
