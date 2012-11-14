require 'httpclient'
require 'nokogiri'
require 'yaml'

module NexusCli
  class RemoteFactory 
    class << self
      attr_reader :configuration
      attr_reader :connection

      def create(overrides, ssl_verify=true)
        @configuration = Configuration::parse(overrides)
        @connection = Connection.new(configuration, ssl_verify)
        running_nexus_pro? ? ProRemote.new(overrides, ssl_verify) : OSSRemote.new(overrides, ssl_verify)
      end

      private

      def running_nexus_pro?
        return connection.status['edition_long'] == "Professional" ? true : false
      end
    end
  end
end
