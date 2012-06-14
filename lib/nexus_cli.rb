require 'nexus_cli/tasks'
require 'nexus_cli/cli'
require 'nexus_cli/errors'
require 'nexus_cli/kernel'
require 'nexus_cli/remote'

module NexusCli
  class << self
    def root
      @root ||= Pathname.new(File.expand_path('../', File.dirname(__FILE__)))
    end
  end
end