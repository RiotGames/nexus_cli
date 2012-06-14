require "nexus_cli/remote"
require "nexus_cli/cli"
require "nexus_cli/errors"
require "nexus_cli/kernel"

module NexusCli
  class << self
    def root
      @root ||= Pathname.new(File.expand_path('../', File.dirname(__FILE__)))
    end
  end
end