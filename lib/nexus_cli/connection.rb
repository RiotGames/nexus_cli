module NexusCli
  class Connection
    attr_reader :nexus
    attr_reader :configuration
    attr_reader :ssl_verify

    def initialize(configuration, ssl_verify)
      @configuration = configuration
      @ssl_verify = ssl_verify
      @nexus = setup_nexus(configuration)
    end

    # Returns an HTTPClient instance with settings to connect
    # to a Nexus server.
    #
    # @return [HTTPClient]
    def setup_nexus(configuration)
      client = HTTPClient.new
      client.send_timeout = 6000
      client.receive_timeout = 6000
      # https://github.com/nahi/httpclient/issues/63
      client.set_auth(nil, configuration['username'], configuration['password'])
      client.www_auth.basic_auth.challenge(configuration['url'])
      client.ssl_config.verify_mode = OpenSSL::SSL::VERIFY_NONE unless ssl_verify
      
      client
    end

    # Joins a given url to the current url stored in the configuraiton
    # and returns the combined String.
    #
    # @param [String] url
    #
    # @return [String]
    def nexus_url(url)
      File.join(configuration['url'], url)
    end

    # Gets that current status of the Nexus server. On a non-error
    # status code, returns a Hash of values from the server.
    #
    # @return [Hash]
    def status
      response = nexus.get(nexus_url("service/local/status"))
      case response.status
      when 200
        doc = REXML::Document.new(response.content).elements["/status/data"]
        data = Hash.new
        data['app_name'] = doc.elements["appName"].text
        data['version'] = doc.elements["version"].text
        data['edition_long'] = doc.elements["editionLong"].text
        data['state'] = doc.elements["state"].text
        data['started_at'] = doc.elements["startedAt"].text
        data['base_url'] = doc.elements["baseUrl"].text
        return data
      when 401
        raise PermissionsException
      when 503
        raise CouldNotConnectToNexusException
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end
    end

    # Transforms a given [String] into a sanitized version by
    # replacing spaces with underscores and downcasing.
    # 
    # @param  unsanitized_string [String] the String to sanitize
    # 
    # @return [String] the sanitized String
    def sanitize_for_id(unsanitized_string)
      unsanitized_string.gsub(" ", "_").downcase
    end

    # Determines whether or not the Nexus server being
    # connected to is running Nexus Pro.
    def running_nexus_pro?
      status['edition_long'] == "Professional"
    end
  end
end