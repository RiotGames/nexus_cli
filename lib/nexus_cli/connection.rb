require 'open-uri'
require 'tempfile'

module NexusCli
  class Connection < Faraday::Connection

    include Celluloid

    NEXUS_REST_ENDPOINT = "service/local/".freeze

    attr_reader :default_repository

    # Creates a new instance of the Connection class
    #
    # @param  configuration [NexusCli::Configuration] the nexus configuration
    def initialize(configuration)
      options = {}
      options[:ssl] = {verify: configuration.ssl_verify}

      options[:builder] = Faraday::Builder.new do |builder|
        builder.request :json
        builder.request :url_encoded
        builder.request :basic_auth, configuration.username, configuration.password
        builder.response :nexus_response
        builder.response :status_code_handler
        builder.adapter :net_http_persistent
      end

      server_uri = Addressable::URI.parse(configuration.server_url).to_hash

      server_uri[:path] = server_uri[:path]

      super(Addressable::URI.new(server_uri), options)
      @headers[:accept] = 'application/json'
      @headers[:content_type] = 'application/json'
      @headers[:user_agent] = "NexusCli v#{NexusCli::VERSION}"

      @default_repository = configuration.repository
    end

    def run_request(*args)
      super
    rescue Errors::HTTPError => ex
      abort ex
    rescue Faraday::Error::ConnectionFailed => ex
      abort Errors::ConnectionFailed.new(ex)
    rescue Faraday::Error::TimeoutError => ex
      abort Errors::TimeoutError.new(ex)
    rescue Faraday::Error::ClientError => ex
      abort Errors::ClientError.new(ex)
    end

    # Stream the response body of a remote URL to a file on the local file system
    #
    # @param [String] target
    #   a URL to stream the response body from
    # @param [String] destination
    #   a location on disk to stream the content of the response body to
    def stream(target, destination)
      FileUtils.mkdir_p(File.dirname(destination))

      target  = Addressable::URI.parse(target)
      headers = {}

      unless ssl[:verify]
        headers.merge!(ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE)
      end

      local = Tempfile.new('nexus-stream')
      local.binmode

      open(target, 'rb', headers) do |remote|
        until remote.eof?
          local.write(remote.read(1024))
        end
      end

      local.flush

      FileUtils.mv(local.path, destination)
    rescue OpenURI::HTTPError => ex
      abort(ex)
    ensure
      local.close(true) unless local.nil?
    end
  end
end
