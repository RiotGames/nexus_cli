require 'extlib'
require 'chozo'

module NexusCli
  class Configuration
    DEFAULT_FILE = "~/.nexus_cli".freeze

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
        new(overrides)
      end

      # Creates a new instance of the Configuration object from the config file
      #
      #
      # @return [NexusCli::Configuration]
      def from_file
        config = YAML.load_file(file_path)
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
    end

    include Chozo::VariaModel

    attribute :url,
      type: String,
      required: true

    attribute :repository,
      type: String,
      required: true,
      coerce: lambda { |m|
        m = m.is_a?(String) ? m.gsub(' ', '_').downcase : m
      }

    attribute :username,
      type: String,
      required: true

    attribute :password,
      type: String,
      required: true

    def initialize(options)
      mass_assign(options)
      self.repository = options[:repository]
    end
  end
end
