module NexusCli
  class BaseRemote
    attr_reader :configuration
    attr_reader :connection

    extend Forwardable
    def_delegators :@connection, :status, :nexus_url, :nexus, :sanitize_for_id

    # @param [Hash] overrides
    # @param [Boolean] ssl_verify
    def initialize(overrides, ssl_verify=true)
      @configuration = Configuration::parse(overrides)
      @connection = Connection.new(configuration, ssl_verify)
    end

    # Parses a given artifact string into its
    # four, distinct, Maven pieces.
    # 
    # @param  artifact [String] the Maven identifier
    # 
    # @return [Array<String>] an Array with four elements
    def parse_artifact_string(artifact)
      split_artifact = artifact.split(":")
      if(split_artifact.size < 4)
        raise ArtifactMalformedException
      end
      group_id, artifact_id, version, extension = split_artifact
      version.upcase! if version.casecmp("latest")
      return group_id, artifact_id, version, extension
    end
  end
end