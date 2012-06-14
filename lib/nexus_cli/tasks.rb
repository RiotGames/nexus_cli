require 'thor'

module NexusCli
  module Tasks
    def self.included(base)
      base.send :include, ::Thor::Actions
      base.class_eval do

        desc "pull_artifact artifact", "Pulls an artifact from Nexus and places it on your machine."
        method_option :destination, :default => nil # defaults to the current working directory
        def pull_artifact(artifact)
          begin
            path_to_artifact = Remote.pull_artifact(artifact, options[:destination])
            puts "Artifact has been retrived and can be found at path: #{path_to_artifact}"
          rescue NexusCliError => e
            puts e.message
            exit e.status_code
          end
        end

        desc "push_artifact artifact file", "Pushes an artifact from your machine onto the Nexus."
        def push_artifact(artifact, file)
          Remote.push_artifact(artifact, file)
          puts "Artifact #{artifact} has been successfully pushed to Nexus."
        end

        desc "get_artifact_info artifact", "Gets and returns the XML information about a particular artifact."
        def get_artifact_info(artifact)
          begin
            puts Remote.get_artifact_info(artifact)
          rescue NexusCliError => e
            puts e.message
            exit e.status_code
          end
        end
      end
    end
  end
end