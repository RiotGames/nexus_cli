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

  class MissingSettingsFileException < NexusCliError
    def message
      "The .nexus_cli file is missing or corrupt."
    end
    status_code(103)
  end

  class NonSecureConnectionException < NexusCliError
    def message
      "Your communication with a server using an SSL certificate failed during validation. You may want to try the --insecure option."
    end
    status_code(104)
  end

  class CouldNotConnectToNexusException < NexusCliError
    def message
      "Could not connect to Nexus. Please ensure the url in .nexus_cli is reachable."
    end
    status_code(105)
  end

  class NoMatchingStagingProfileException < NexusCliError
    def message
      "No Staging Profile was found that matched your groupdId:artifactId path. You will need to check your syntax or administrate the Nexus."
    end
    status_code(106)
  end

  class PermissionsException < NexusCliError
    def message
      "Your request was denied by the Nexus server due to a permissions error. You will need to administer the Nexus or use a different user/password in .nexus_cli."
    end
    status_code(107)
  end
end