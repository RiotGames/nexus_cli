require 'extlib'

module NexusCli
  module Configuration
    class << self
      def parse(overrides)
        config_path = File.expand_path("~/.nexus_cli")
        config = File.exists?(config_path) ? YAML::load_file(config_path) : Hash.new
        if config.nil? && (overrides.nil? || overrides.empty?)
          raise MissingSettingsFileException
        end
        overrides.each{|key, value| config[key] = value} unless overrides.nil? || overrides.empty?
        validate_config(config)
        config
      end

      def validate_config(configuration)
        ["url", "repository", "username","password"].each do |key|
          raise InvalidSettingsException.new(key) if configuration[key].blank?
        end
      end
    end
  end
end