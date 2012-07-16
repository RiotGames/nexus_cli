require 'nexus_cli/tasks'
require 'nexus_cli/cli'
require 'nexus_cli/errors'
require 'nexus_cli/kernel'
require 'nexus_cli/nexus_remote_factory'
require 'nexus_cli/nexus_oss_remote'
require 'nexus_cli/nexus_pro_remote'

module NexusCli
  class << self
    def root
      @root ||= Pathname.new(File.expand_path('../', File.dirname(__FILE__)))
    end
  end
end