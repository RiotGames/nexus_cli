APP_ROOT = File.expand_path('../../', __FILE__)

require 'nexus_cli'
require 'webmock/rspec'

NexusCli::Configuration.path = File.join(APP_ROOT, "spec", "fixtures", "nexus.config")
