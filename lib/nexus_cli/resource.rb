module NexusCli
  class Resource

    FILE_NAME_KEYS = [ :a, :v, :e ].freeze

    include Celluloid

    def initialize(connection_registry)
      @connection_registry = connection_registry
    end

    # @return [NexusCli::Connection]
    def connection
      @connection_registry[:connection_pool]
    end

    # @param [Symbol] method
    def rest_request(method, path, *args)
      unless path.start_with?(Connection::NEXUS_REST_ENDPOINT)
        path.prepend(Connection::NEXUS_REST_ENDPOINT)
      end

      raw_request(method, path, *args).body
    end

    def base_request(method, path, *args)
      raw_request(method, path, *args).body
    end

    # Converts an artifact identifier string into a file
    # name.
    #
    # @param  artifact_id [String]
    # 
    # @example file_name_for("com:my-test:1.0.1:tgz") => "my-test-1.0.1.tgz"
    # 
    # @return [String]
    def file_name_for(artifact_id)
      parts = artifact_id.to_artifact_hash.slice(*FILE_NAME_KEYS)
      "#{parts[:a]}-#{parts[:v]}.#{parts[:e]}"
    end

    def repository_path_for(artifact_id)
      artifact_id_hash = artifact_id.to_artifact_hash
      "#{artifact_id_hash[:g].gsub('.', '/')}/#{artifact_id_hash[:a]}/#{artifact_id_hash[:v]}"
    end

    private
  
      # @param [Symbol] method
      def raw_request(method, path, *args)
        unless Connection::METHODS.include?(method)
          #raise Errors::HTTPUnknownMethod, "unknown http method: #{method}"
        end

        connection.send(method, path, *args)
      rescue => ex
        abort(ex)
      end
  end
end
