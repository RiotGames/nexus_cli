require 'yaml'

module NexusCli
  class Configuration
    DEFAULT_FILE = (ENV['HOME'] ? "~/.nexus_cli" : "/root/.nexus_cli").freeze

    class << self
      # The filepath to the nexus cli configuration file
      #
      # @return [String]
      def file_path
        File.expand_path(ENV['NEXUS_CONFIG'] || File.expand_path(DEFAULT_FILE))
      end

      # Creates a new instance of the Configuration object based on some overrides
      #
      # @param [Hash] overrides
      #
      # @return [NexusCli::Configuration]
      def from_overrides(overrides)
        raise MissingSettingsFileException unless overrides
        overrides = overrides.with_indifferent_access

        configuration = (load_config || Hash.new).with_indifferent_access
        configuration.merge!(overrides)
        new(configuration)
      end

      # Creates a new instance of the Configuration object from the config file
      #
      #
      # @return [NexusCli::Configuration]
      def from_file
        config = load_config
        raise MissingSettingsFileException unless config
        config = config.with_indifferent_access
        new(config)
      end

      # Validates an instance of the Configuration object and raises when there
      # is an error with it
      #
      # @param  config [NexusCli::Configuration]
      #
      # @raise [NexusCli::InvalidSettingsException]
      def validate!(config)
        unless config.valid?
          raise InvalidSettingsException.new(config.errors)
        end
      end

      private

        # Loads the config file
        #
        # @return [Hash]
        def load_config
          begin
            config = YAML.load_file(file_path)
          rescue Errno::ENOENT
            nil
          end
        end
    end

    def validate!
      self.class.validate!(self)
    end

    def valid?
      errors.empty?
    end

    def errors
      result = Hash.new
      result[:url] = ["url required"] unless url.is_a?(String) && url.size > 0
      result[:repository] = ["repository required"] unless repository.is_a?(String) && repository.size > 0
      result
    end

    attr_accessor :url
    attr_accessor :repository
    attr_accessor :username
    attr_accessor :password

    def initialize(options)
      @url = options[:url]
      @repository = options[:repository]
      @username = options[:username]
      @password = options[:password]

      if @repository.is_a?(String)
        @repository = @repository.gsub(' ', '_')
      end
    end

    def [](attr)
      self.instance_variable_get('@' + attr.to_s)
    end
  end
end
