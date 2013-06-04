require 'httpclient'
require 'yaml'

module NexusCli
  class RemoteFactory 
    class << self
      attr_reader :configuration
      attr_reader :connection

      # Creates a new Nexus Remote that can connect to and communicate with
      # the Nexus server.
      #
      # @param  [Hash] overrides
      # @param  [Boolean] ssl_verify
      # 
      # @return [NexusCli::ProRemote, NexusCli::OSSRemote]
      def create(overrides, ssl_verify=true)
        @configuration = overrides ? Configuration.from_overrides(overrides) : Configuration.from_file
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
