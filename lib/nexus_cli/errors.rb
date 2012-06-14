module NexusCli
  class NexusCliError < StandardError
    class << self
      def status_code(code)
        define_method(:status_code) { code }
      end
    end
  end

  class ArtifactMalformedException < NexusCliError
    def message
      "Please submit your request using 4 colon-separated values. `groupId:artifactId:version:extension`"
    end
    status_code(100)
  end

  class ArtifactNotFoundException < NexusCliError
    def message
      "The artifact you requested information for could not be found. Please ensure it exists inside the Nexus."
    end
    status_code(101)
  end

  class InvalidSettingsException < NexusCliError
    def initialize(key)
      @missing_setting = key
    end
    
    def message
      "The .nexus_cli file is missing the value: #{@missing_setting}"
    end
    status_code(102)
  end

  class MissingSettingsFile < NexusCliError
    def message
      "The .nexus_cli file is missing or corrupt."
    end
    status_code(103)
  end
end