require 'json'

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
    def initialize(errors)
      @errors = errors
    end

    def message
      "Your configuration has an error: #{@errors}"
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
      "Submit your search request specifying one or more 3 colon-separated values: `key:type:value`. The available search types are `equal`, `matches`, `bounded`, and `notequal`."
    end
    status_code(109)
  end

  class BadSearchRequestException < NexusCliError
    def message
      "Your request was denied by the Nexus server due to a bad request. Check that your search parameters contain valid values."
    end
    status_code(110)
  end

  class BadSettingsException < NexusCliError
    def initialize(body)
      @server_response = JSON.pretty_generate(JSON.parse(body))
    end

    def message
      %{Your global_settings.json file is malformed and could not be uploaded to Nexus.
The output from the server was:
#{@server_response}}
    end
    status_code(111)
  end

  class CreateRepsitoryException < NexusCliError
    def initialize(body)
      @server_response = JSON.pretty_generate(JSON.parse(body))
    end

    def message
      %{Your create repository command failed due to the following:
#{@server_response}}
    end
    status_code(112)
  end

  class RepositoryDoesNotExistException < NexusCliError
    def message
      "The repository you are trying to delete does not exist."
    end
    status_code(113)
  end

  class RepositoryNotFoundException < NexusCliError
    def message
      "The repository you provided could not be found. Please ensure the repository exists."
    end
    status_code(114)
  end

  class UnexpectedStatusCodeException < NexusCliError
    def initialize(code)
      @code = code
    end

    def  message
      "The server responded with a #{@code} status code which is unexpected. Please submit a bug."
    end
    status_code(115)
  end

  class N3ParameterMalformedException < NexusCliError
    def message
      "Submit your tag request specifying one or more 2 colon-separated values: `key:value`. The key can only consist of alphanumeric characters."
    end
    status_code(116)
  end

  class CreateUserException < NexusCliError
    def initialize(body)
      @server_response = JSON.pretty_generate(JSON.parse(body))
    end

    def message
      %{Your create user command failed due to the following:
#{@server_response}}
    end
    status_code(117)
  end

  class UserNotFoundException < NexusCliError
    def initialize(id)
      @id = id
    end

    def message
      "A user with the ID of #{@id} could not be found. Please ensure it exists."
    end
    status_code(118)
  end

  class UpdateUserException < NexusCliError
    def initialize(body)
      @server_response = JSON.pretty_generate(JSON.parse(body))
    end

    def message
      %{Your update user command failed due to the following:
#{@server_response}}
    end
    status_code(119)
  end

  class InvalidCredentialsException < NexusCliError
    def message
      "Invalid Credentials were supplied. Please make sure you are passing the correct values."
    end
    status_code(120)
  end

  class NotProxyRepositoryException < NexusCliError
    def initialize(repository_id)
      @repository_id = repository_id
    end

    def message
      "The #{@repository_id} repository is not a Proxy repository and cannot subscribe to artifact updates."
    end
    status_code(121)
  end

  class LicenseInstallFailure < NexusCliError
    def message
      "Either your Nexus already has a license installed or there was a problem with the file you uploaded."
    end
    status_code(122)
  end

  class InvalidLoggingLevelException < NexusCliError
    def message
      "Logging level must be set to one of either INFO, DEBUG, or ERROR."
    end
    status_code(123)
  end

  class N3NotFoundException < NexusCliError
    def message
      "The artifact does not have any custom metadata added yet."
    end
    status_code(124)
  end

  class SSLException < NexusCliError
    def message
      "You are attempting to communicate securely with a server that has an untrusted certificate. Please ensure your certificate is correct or set ssl_verify to false."
    end
    status_code(125)
  end

  class RepositoryInGroupException < NexusCliError
    def message
      "You are attempting to add a repository that is already a part of this group."
    end
    status_code(126)
  end

  class RepositoryNotInGroupException < NexusCliError
    def message
      "You are attempting to remove a repository that isn't a part of the group."
    end
    status_code(127)
  end
  
  class NexusHTTP404 < NexusCliError
    def initialize(body)
      @server_response = body
    end

    def message
      %{Your command failed and the server returned an error code. The output of the response was:
#{@server_response}}
    end
    status_code(128)
  end
end