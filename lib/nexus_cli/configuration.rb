require 'extlib'

module NexusCli
  module Configuration
    DEFAULT_FILE = "~/.nexus_cli".freeze

    class << self
      attr_writer :path

      # The filepath to the nexus cli configuration file
      #
      # @return [String]
      def path
        @path || File.expand_path(ENV['NEXUS_CONFIG'] || DEFAULT_FILE)
      end

      # @param [Hash] overrides
      #
      # @return [Hash]
      def parse(overrides = {})
        config = File.exists?(self.path) ? YAML::load_file(self.path) : Hash.new

        if config.nil? && (overrides.nil? || overrides.empty?)
          raise MissingSettingsFileException
        end

        unless overrides.nil? || overrides.empty?
          overrides.each { |key, value| config[key] = value }
        end

        validate_config(config)

        config["repository"] = config["repository"].gsub(" ", "_").downcase
        config
      end

      def validate_config(configuration)
        ["url", "repository", "username", "password"].each do |key|
          raise InvalidSettingsException.new(key) if configuration[key].blank?
        end
      end
    end
  end
end