require 'nexus_cli/tasks'
require 'nexus_cli/cli'
require 'nexus_cli/errors'
require 'nexus_cli/kernel'
require 'nexus_cli/nexus_remote_factory'
require 'nexus_cli/nexus_oss_remote'
require 'nexus_cli/nexus_pro_remote'
require 'nexus_cli/configuration'
require 'nexus_cli/n3_metadata'

module NexusCli

  DEFAULT_ACCEPT_HEADER = {"Accept" => "application/json"}
  DEFAULT_CONTENT_TYPE_HEADER = {"Content-Type" => "application/json"}

  class << self
    def root
      @root ||= Pathname.new(File.expand_path('../', File.dirname(__FILE__)))
    end

    def ui
      @ui ||= Thor::Shell::Color.new
    end
  end
end