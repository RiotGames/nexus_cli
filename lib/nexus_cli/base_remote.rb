module NexusCli
  class BaseRemote
    attr_reader :configuration
    attr_reader :connection

    extend Forwardable
    def_delegators :@connection, :status, :nexus_url, :nexus, :sanitize_for_id, :running_nexus_pro?

    # @param [Hash] overrides
    # @param [Boolean] ssl_verify
    def initialize(overrides, ssl_verify=true)
      @configuration = overrides ? Configuration.from_overrides(overrides) : Configuration.from_file
      @connection = Connection.new(configuration, ssl_verify)
    end
  end
end
