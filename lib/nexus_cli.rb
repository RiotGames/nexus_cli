require 'nexus_cli/errors'
require 'nexus_cli/kernel'

module NexusCli
  DEFAULT_ACCEPT_HEADER = {
    "Accept" => "application/json"
  }.freeze
  
  DEFAULT_CONTENT_TYPE_HEADER = {
    "Content-Type" => "application/json"
  }.freeze

  autoload :Tasks, 'nexus_cli/tasks'
  autoload :Cli, 'nexus_cli/cli'
  autoload :RemoteFactory, 'nexus_cli/remote_factory'
  autoload :OSSRemote, 'nexus_cli/oss_remote'
  autoload :ProRemote, 'nexus_cli/pro_remote'
  autoload :Configuration, 'nexus_cli/configuration'
  autoload :N3Metadata, 'nexus_cli/n3_metadata'

  class << self
    def root
      @root ||= Pathname.new(File.expand_path('../', File.dirname(__FILE__)))
    end

    def ui
      @ui ||= Thor::Shell::Color.new
    end
  end
end
