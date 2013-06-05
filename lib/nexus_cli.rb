require 'forwardable'
require 'addressable/uri'
require 'faraday'
require 'faraday_middleware'
require 'nexus_cli/errors'
require 'rexml/document'
require 'yaml'
require 'active_support/core_ext/hash'

module NexusCli
  DEFAULT_ACCEPT_HEADER = {
    "Accept" => "application/json"
  }.freeze
  
  DEFAULT_CONTENT_TYPE_HEADER = {
    "Content-Type" => "application/json"
  }.freeze

  autoload :Tasks, 'nexus_cli/tasks'
  autoload :Cli, 'nexus_cli/cli'
  autoload :Connection, 'nexus_cli/connection'
  autoload :RemoteFactory, 'nexus_cli/remote_factory'
  autoload :BaseRemote, 'nexus_cli/base_remote'
  autoload :OSSRemote, 'nexus_cli/remote/oss_remote'
  autoload :ProRemote, 'nexus_cli/remote/pro_remote'
  autoload :Configuration, 'nexus_cli/configuration'
  autoload :N3Metadata, 'nexus_cli/n3_metadata'
  autoload :ArtifactActions, 'nexus_cli/mixins/artifact_actions'
  autoload :GlobalSettingsActions, 'nexus_cli/mixins/global_settings_actions'
  autoload :UserActions, 'nexus_cli/mixins/user_actions'
  autoload :RepositoryActions, 'nexus_cli/mixins/repository_actions'
  autoload :LoggingActions, 'nexus_cli/mixins/logging_actions'
  autoload :CustomMetadataActions, 'nexus_cli/mixins/pro/custom_metadata_actions'
  autoload :SmartProxyActions, 'nexus_cli/mixins/pro/smart_proxy_actions'

  class << self
    def root
      @root ||= Pathname.new(File.expand_path('../', File.dirname(__FILE__)))
    end

    def ui
      @ui ||= Thor::Shell::Color.new
    end
  end
end