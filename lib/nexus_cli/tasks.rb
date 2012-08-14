require 'thor'

module NexusCli
  module Tasks
    def self.included(base)
      base.send :include, ::Thor::Actions
      base.class_eval do

        map 'pull'          => :pull_artifact
        map 'push'          => :push_artifact
        map 'info'          => :get_artifact_info
        map 'custom'        => :get_artifact_custom_info
        map 'custom_raw'    => :get_artifact_custom_info_n3
        map 'config'        => :get_nexus_configuration
        map 'status'        => :get_nexus_status
        map 'search'        => :search_for_artifacts
        map 'search_custom' => :search_artifacts

        class_option :overrides,
          :type => :hash,
          :default => {},
          :desc => "A hashed list of overrides. Available options are 'url', 'repository', 'username', and 'password'."

        def initialize(*args)
          super
          begin
            @nexus_remote = Factory.create(options[:overrides])
          rescue NexusCliError => e
            say e.message, :red
            exit e.status_code
          end
        end

        method_option :destination,
          :type => :string,
          :default => nil,
          :desc => "A different folder other than the current working directory."
        desc "pull_artifact artifact", "Pulls an artifact from Nexus and places it on your machine."
        def pull_artifact(artifact)
          path_to_artifact = @nexus_remote.pull_artifact(artifact, options[:destination])
          say "Artifact has been retrived and can be found at path: #{path_to_artifact}", :green
        end

        desc "push_artifact artifact file", "Pushes an artifact from your machine onto the Nexus."
        def push_artifact(artifact, file)
          @nexus_remote.push_artifact(artifact, file)
          say "Artifact #{artifact} has been successfully pushed to Nexus.", :green
        end

        desc "get_artifact_info artifact", "Gets and returns the metadata in XML format about a particular artifact."
        def get_artifact_info(artifact)
          say @nexus_remote.get_artifact_info(artifact), :green
        end

        desc "search_for_artifacts", "Prints out some information about some junk."
        def search_for_artifacts(artifact)
          @nexus_remote.search_for_artifacts(artifact).each{|output| say output, :green}
        end

        desc "get_artifact_custom_info artifact", "Gets and returns the custom metadata in XML format about a particular artifact."
        def get_artifact_custom_info(artifact)
          say @nexus_remote.get_artifact_custom_info(artifact), :green
        end

        desc "get_artifact_custom_info_n3 artifact", "Gets and returns the custom metadata in Nexus n3 format about a particular artifact."
        def get_artifact_custom_info_n3(artifact)
          raise NotNexusProException unless @nexus_remote.kind_of? ProRemote
          say @nexus_remote.get_artifact_custom_info_n3(artifact), :green
        end

        desc "update_artifact_custom_info artifact param1 param2 ...", "Updates the artifact custom metadata with the given key-value pairs."
        def update_artifact_custom_info(artifact, *params)
          raise NotNexusProException unless @nexus_remote.kind_of? ProRemote
          @nexus_remote.update_artifact_custom_info(artifact, *params)
          say "Custom metadata for artifact #{artifact} has been successfully pushed to Nexus.", :green
        end

        desc "update_artifact_custom_info_n3 artifact file", "Updates the artifact custom metadata by pushing the Nexus custom artifact file (n3) from your machine onto the Nexus."
        def update_artifact_custom_info_n3(artifact, file)
          raise NotNexusProException unless @nexus_remote.kind_of? ProRemote
          @nexus_remote.update_artifact_custom_info_n3(artifact, file)
          say "Custom metadata for artifact #{artifact} has been successfully pushed to Nexus.", :green
        end

        desc "clear_artifact_custom_info artifact", "Clears the artifact custom metadata."
        def clear_artifact_custom_info(artifact)
          raise NotNexusProException unless @nexus_remote.kind_of? ProRemote
          @nexus_remote.clear_artifact_custom_info(artifact)
          say "Custom metadata for artifact #{artifact} has been successfully cleared.", :green
        end

        desc "search_artifacts param1 param2 ... ", "Searches for artifacts using artifact metadata and returns the result as a list with items in XML format."
        def search_artifacts(*params)
          raise NotNexusProException unless @nexus_remote.kind_of? ProRemote
          say (s = @nexus_remote.search_artifacts(*params)) == "" ? "No search results." : s, :green
        end

        desc "get_nexus_configuration", "Prints out configuration from the .nexus_cli file that helps inform where artifacts will be uploaded."
        def get_nexus_configuration
          config = @nexus_remote.configuration
          say "********* Reading CLI configuration from #{File.expand_path('~/.nexus_cli')} *********", :blue
          say "Nexus URL: #{config['url']}", :blue
          say "Nexus Repository: #{config['repository']}", :blue
        end

        desc "get_nexus_status", "Prints out information about the Nexus instance."
        def get_nexus_status
          data = @nexus_remote.status
          say "********* Getting Nexus status from #{data['base_url']} *********", :blue
          say "Application Name: #{data['app_name']}", :blue
          say "Version: #{data['version']}", :blue
          say "Edition: #{data['edition_long']}", :blue
          say "State: #{data['state']}", :blue
          say "Started At: #{data['started_at']}", :blue
          say "Base URL: #{data['base_url']}", :blue
        end

        desc "get_global_settings", "Prints out your Nexus' current setttings and saves them to a file."
        def get_global_settings
          @nexus_remote.get_global_settings
          say "Your current Nexus global settings have been written to the file: ~/.nexus/global_settings.json", :blue
        end

        method_option :json, 
          :type => :string,
          :default => nil,
          :desc => "A String of the JSON you wish to upload."
        desc "upload_global_settings", "Uploads a global_settings.json file to your Nexus to update its settings."
        def upload_global_settings
          @nexus_remote.upload_global_settings(options[:json])
          say "Your global_settings.json file has been uploaded to Nexus", :blue
        end

        desc "reset_global_settings", "Resets your Nexus global_settings to their out-of-the-box defaults."
        def reset_global_settings
          @nexus_remote.reset_global_settings
          say "Your Nexus global settings have been reset to their default values", :blue
        end

        desc "create_repository name", "Creates a new Repository with the provided name."
        def create_repository(name)
          if @nexus_remote.create_repository(name)
            say "A new Repository named #{name} has been created.", :blue
          end
        end

        desc "delete_repository name", "Deletes a Repository with the provided name."
        def delete_repository(name)
          if @nexus_remote.delete_repository(name)
            say "The Repository named #{name} has been deleted.", :blue
          end
        end

        desc "get_repository_info name", "Finds and returns information about the provided Repository."
        def get_repository_info(name)
          say @nexus_remote.get_repository_info(name), :green
        end
      end
    end
  end
end
