module NexusCli
  class Connection < Faraday::Connection

    NEXUS_REST_ENDPOINT = "service/local".freeze

    # Creates a new instance of the Connection class
    #
    # @param  server_url [String] the nexus server url
    # @param  configuration [NexusCli::Configuration] the nexus configuration
    def initialize(server_url, configuration = Configuration.from_file)
      options = {}
      options[:ssl] = {verify: configuration.ssl_verify}

      options[:builder] = Faraday::Builder.new do |builder|
        builder.request :json
        builder.request :url_encoded
        builder.request :basic_auth, configuration.username, configuration.password
        builder.response :json
        builder.adapter :net_http_persistent
      end

      server_uri = Addressable::URI.parse(server_url).to_hash

      server_uri[:path] = File.join(server_uri[:path], NEXUS_REST_ENDPOINT)

      super(Addressable::URI.new(server_uri), options)
      @headers[:accept] = 'application/json'
      @headers[:content_type] = 'application/json'
      @headers[:user_agent] = "NexusCli v#{NexusCli::VERSION}"
    end
  end
end
