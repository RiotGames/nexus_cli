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
      "The .nexus_cli file or your overrides are missing the value: #{@missing_setting}"
    end
    status_code(102)
  end

  class MissingSettingsFileException < NexusCliError
    def message
      "The .nexus_cli file is missing or corrupt. You can either fix the .nexus_cli file or pass the --overrides hash."
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
      "Could not connect to Nexus. Please ensure the url you are using is reachable."
    end
    status_code(105)
  end

  class PermissionsException < NexusCliError
    def message
      "Your request was denied by the Nexus server due to a permissions error. You will need to administer the Nexus or use a different user/password in .nexus_cli."
    end
    status_code(106)
  end

  class BadUploadRequestException < NexusCliError
    def message
      %{Your request was denied by the Nexus server due to a bad request and your artifact has not been uploaded.
This could mean several things:
  Your .nexus_cli['repository'] is invalid.
  The artifact with this identifier already exists inside the repository and that repository does not allow multiple deployments.}
    end
    status_code(107)
  end

  class NotNexusProException < NexusCliError
    def message
      "You cannot use this feature unless you are using Nexus Professional."
    end
    status_code(108)
  end

  class SearchParameterMalformedException < NexusCliError
    def message
      %{Submit your search request specifying the search key, type, and value.
The available search types are `equal`, `matches`, `bounded`, and `notequal`.}
    end
    status_code(109)
  end
end