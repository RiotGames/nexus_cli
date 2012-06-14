require 'thor'

module NexusCli
  class Cli < Thor
    include NexusCli::Tasks
  end
end