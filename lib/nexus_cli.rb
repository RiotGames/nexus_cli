require 'nexus_cli/core_ext'
require 'nexus_cli/errors'
require 'addressable/uri'
require 'faraday'
require 'faraday_middleware'
require 'rexml/document'
require 'yaml'
require 'celluloid'
require 'active_support/core_ext/hash'
require 'buff/config/json'

module NexusCli
  require_relative 'nexus_cli/client'
  require_relative 'nexus_cli/configuration'
  require_relative 'nexus_cli/connection'
  require_relative 'nexus_cli/resource'
  require_relative 'nexus_cli/resources'
  require_relative 'nexus_cli/nexus_object'
  require_relative 'nexus_cli/nexus_objects'
  require_relative 'nexus_cli/middleware'

  class << self
    def new(options = nil)
      Client.new(options)
    end

    def root
      @root ||= Pathname.new(File.expand_path('../', File.dirname(__FILE__)))
    end
  end
end
