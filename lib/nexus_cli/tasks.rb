require 'thor'
require 'highline'

module NexusCli
  module Tasks
    def self.included(base)
      base.send :include, ::Thor::Actions
      base.class_eval do

        map 'pull'          => :pull_artifact
        map 'push'          => :push_artifact
        map 'info'          => :get_artifact_info
        map 'custom'        => :get_artifact_custom_info
        map 'config'        => :get_nexus_configuration
        map 'status'        => :get_nexus_status
        map 'search'        => :search_for_artifacts
        map 'search_custom' => :search_artifacts_custom
        map 'transfer'      => :transfer_artifact

        class_option :overrides,
          :type => :hash,
          :default => {},
          :desc => "A hashed list of overrides. Available options are 'url', 'repository', 'username', and 'password'."

        class_option :ssl_verify,
          :type => :boolean,
          :default => true,
          :desc => "Set to false to disable SSL Verification."

        method_option :destination,
          :type => :string,
          :default => nil,
          :desc => "A different folder other than the current working directory."
        desc "pull_artifact artifact", "Pulls an artifact from Nexus and places it on your machine."
        def pull_artifact(artifact)
          path_to_artifact = nexus_remote.pull_artifact(artifact, options[:destination])
          say "Artifact has been retrived and can be found at path: #{path_to_artifact}", :green
        end

        desc "push_artifact artifact file", "Pushes an artifact from your machine onto the Nexus."
        def push_artifact(artifact, file)
          nexus_remote.push_artifact(artifact, file)
          say "Artifact #{artifact} has been successfully pushed to Nexus.", :green
        end

        desc "get_artifact_info artifact", "Gets and returns the metadata in XML format about a particular artifact."
        def get_artifact_info(artifact)
          say nexus_remote.get_artifact_info(artifact), :green
        end

        desc "search_for_artifacts", "Prints out some information about some junk."
        def search_for_artifacts(artifact)
          nexus_remote.search_for_artifacts(artifact).each{|output| say output, :green}
        end

        desc "get_artifact_custom_info artifact", "Gets and returns the custom metadata in XML format about a particular artifact."
        def get_artifact_custom_info(artifact)
          raise NotNexusProException unless nexus_remote.kind_of? ProRemote
          say nexus_remote.get_artifact_custom_info(artifact), :green
        end

        desc "update_artifact_custom_info artifact param1 param2 ...", "Updates the artifact custom metadata with the given key-value pairs."
        def update_artifact_custom_info(artifact, *params)
          raise NotNexusProException unless nexus_remote.kind_of? ProRemote
          nexus_remote.update_artifact_custom_info(artifact, *params)
          say "Custom metadata for artifact #{artifact} has been successfully pushed to Nexus.", :green
        end

        desc "clear_artifact_custom_info artifact", "Clears the artifact custom metadata."
        def clear_artifact_custom_info(artifact)
          raise NotNexusProException unless nexus_remote.kind_of? ProRemote
          nexus_remote.clear_artifact_custom_info(artifact)
          say "Custom metadata for artifact #{artifact} has been successfully cleared.", :green
        end

        desc "search_artifacts_custom param1 param2 ... ", "Searches for artifacts using artifact metadata and returns the result as a list with items in XML format."
        def search_artifacts_custom(*params)
          raise NotNexusProException unless nexus_remote.kind_of? ProRemote
          say (s = nexus_remote.search_artifacts_custom(*params)) == "" ? "No search results." : s, :green
        end

        desc "get_nexus_configuration", "Prints out configuration from the .nexus_cli file that helps inform where artifacts will be uploaded."
        def get_nexus_configuration
          config = nexus_remote.configuration
          say "********* Reading CLI configuration from #{File.expand_path('~/.nexus_cli')} *********", :blue
          say "Nexus URL: #{config['url']}", :blue
          say "Nexus Repository: #{config['repository']}", :blue
        end

        desc "get_nexus_status", "Prints out information about the Nexus instance."
        def get_nexus_status
          data = nexus_remote.status
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
          nexus_remote.get_global_settings
          say "Your current Nexus global settings have been written to the file: ~/.nexus/global_settings.json", :blue
        end

        method_option :json, 
          :type => :string,
          :default => nil,
          :desc => "A String of the JSON you wish to upload."
        desc "upload_global_settings", "Uploads a global_settings.json file to your Nexus to update its settings."
        def upload_global_settings
          nexus_remote.upload_global_settings(options[:json])
          say "Your global_settings.json file has been uploaded to Nexus", :blue
        end

        desc "reset_global_settings", "Resets your Nexus global_settings to their out-of-the-box defaults."
        def reset_global_settings
          nexus_remote.reset_global_settings
          say "Your Nexus global settings have been reset to their default values", :blue
        end

        method_option :proxy,
          :type => :boolean,
          :desc => "True if the new repository should be a proxy repository"
          method_option :url,
          :type => :string,
          :desc => "The url of the actual repository for the proxy repository to use."
        desc "create_repository name", "Creates a new Repository with the provided name."
        def create_repository(name)
          if nexus_remote.create_repository(name, options[:proxy], options[:url])
            say "A new Repository named #{name} has been created.", :blue
          end
        end

        desc "delete_repository name", "Deletes a Repository with the provided name."
        def delete_repository(name)
          if nexus_remote.delete_repository(name)
            say "The Repository named #{name} has been deleted.", :blue
          end
        end

        desc "get_repository_info name", "Finds and returns information about the provided Repository."
        def get_repository_info(name)
          say nexus_remote.get_repository_info(name), :green
        end

        desc "get_users", "Returns XML representing the users in Nexus."
        def get_users
          say nexus_remote.get_users, :green
        end

        method_option :username,
          :type => :string,
          :default => nil,
          :desc => "The username."
        method_option :first_name,
          :type => :string,
          :default => nil,
          :desc => "The first name."
        method_option :last_name,
          :type => :string,
          :default => nil,
          :desc => "The last name."
        method_option :email,
          :type => :string,
          :default => nil,
          :desc => "The email."
        method_option :password,
          :type => :string,
          :default => nil,
          :desc => "The password."
        method_option :enabled,
          :type => :boolean,
          :default => nil,
          :desc => "Whether this new user is enabled or disabled."
        method_option :roles,
          :type => :array,
          :default => [],
          :require => false,
          :desc => "An array of roles."
        desc "create_user", "Creates a new user"
        def create_user         
          params = ask_user(options)

          if nexus_remote.create_user(params) 
            say "A user with the ID of #{params[:userId]} has been created.", :blue
          end
        end

        method_option :username,
          :type => :string,
          :default => nil,
          :desc => "The username."
        method_option :first_name,
          :type => :string,
          :default => nil,
          :desc => "The first name."
        method_option :last_name,
          :type => :string,
          :default => nil,
          :desc => "The last name."
        method_option :email,
          :type => :string,
          :default => nil,
          :desc => "The email."
        method_option :enabled,
          :type => :boolean,
          :default => nil,
          :desc => "Whether this new user is enabled or disabled."
        method_option :roles,
          :type => :array,
          :default => [],
          :require => false,
          :desc => "An array of roles."
        desc "update_user user_id", "Updates a user's details. Leave fields blank for them to remain their current values."
        def update_user(user_id)
          params = ask_user(options, false, false)
          params[:userId] = user_id

          if nexus_remote.update_user(params)
            say "User #{user_id} has been updated.", :blue
          end
        end

        desc "delete_user user_id", "Deletes the user with the given id."
        def delete_user(user_id)
          if nexus_remote.delete_user(user_id)
            say "User #{user_id} has been deleted.", :blue
          end
        end

        method_option :oldPassword,
          :type => :string,
          :default => nil,
          :desc => ""
        method_option :newPassword,
          :type => :string,
          :default => nil,
          :desc => ""
        desc "change_password user_id", "Changes the given user's passwords to a new one."
        def change_password(user_id)

          oldPassword = options[:oldPassword]
          newPassword = options[:newPassword]

          if oldPassword.nil?
            oldPassword = ask_password("Please enter your old password:")
          end
          if newPassword.nil?
            newPassword = ask_password("Please enter your new password:")
          end

          params = {:userId => user_id}
          params[:oldPassword] = oldPassword
          params[:newPassword] = newPassword
          if nexus_remote.change_password(params)
            say "The password for user #{user_id} has been updated.", :blue
          end
        end

        desc "get_pub_sub repository_id", "Returns the publish/subscribe status of the given repository."
        def get_pub_sub(repository_id)
          raise NotNexusProException unless nexus_remote.kind_of? ProRemote
          say nexus_remote.get_pub_sub(repository_id), :green
        end

        desc "enable_artifact_publish repository_id", "Sets a repository to enable the publishing of updates about its artifacts."
        def enable_artifact_publish(repository_id)
          raise NotNexusProException unless nexus_remote.kind_of? ProRemote
          if nexus_remote.enable_artifact_publish(repository_id)
            say "The repository #{repository_id} will now publish updates.", :blue
          end
        end

        desc "disable_artifact_publish repository_id", "Sets a repository to disable the publishing of updates about its artifacts."
        def disable_artifact_publish(repository_id)
          raise NotNexusProException unless nexus_remote.kind_of? ProRemote
          if nexus_remote.disable_artifact_publish(repository_id)
            say "The repository #{repository_id} is no longer publishing updates.", :blue
          end
        end

        desc "enable_artifact_subscribe repository_id", "Sets a repository to subscribe to updates about artifacts."
        def enable_artifact_subscribe(repository_id)
          raise NotNexusProException unless nexus_remote.kind_of? ProRemote
          if nexus_remote.enable_artifact_subscribe(repository_id)
            say "The repository #{repository_id} is now subscribed for artifact updates.", :blue
          end
        end

        desc "disable_artifact_subscribe repository_id", "Sets a repository to stop subscribing to updates about artifacts."
        def disable_artifact_subscribe(repository_id)
          raise NotNexusProException unless nexus_remote.kind_of? ProRemote
          if nexus_remote.disable_artifact_subscribe(repository_id)
            say "The repository #{repository_id} is no longer subscribed for artifact updates.", :blue
          end
        end

        method_option :host,
          :type => :string,
          :desc => "An IP address for the Nexus server at which publishing will be available."
        method_option :port,
          :type => :numeric,
          :desc => "An available port that will be used for Smart Proxy connections."
        desc "enable_smart_proxy", "Enables Smart Proxy on the server."
        def enable_smart_proxy
          raise NotNexusProException unless nexus_remote.kind_of? ProRemote
          say nexus_remote.enable_smart_proxy(options[:host], options[:port])
        end

        desc "disable_smart_proxy", "Disables Smart Proxy on the server."
        def disable_smart_proxy
          raise NotNexusProException unless nexus_remote.kind_of? ProRemote
          say nexus_remote.disable_smart_proxy          
        end

        desc "get_smart_proxy_settings", "Returns the Smart Proxy settings of the server."
        def get_smart_proxy_settings
          raise NotNexusProException unless nexus_remote.kind_of? ProRemote
          say JSON.pretty_generate(JSON.parse(nexus_remote.get_smart_proxy_settings)), :green
        end

        method_option :certificate,
          :type => :string,
          :required => :true,
          :desc => "A path to a file containing a certificate."
        method_option :description,
          :type => :string,
          :required => true,
          :desc => "A description to give to the trusted key. It is probably best to make this meaningful."
        desc "add_trusted_key", "Adds a new trusted key to the Smart Proxy configuration."
        def add_trusted_key
          raise NotNexusProException unless nexus_remote.kind_of? ProRemote
          if nexus_remote.add_trusted_key(options[:certificate], options[:description])
            say "A new trusted key has been added to the nexus.", :blue
          end
        end

        desc "delete_trusted_key key_id", "Deletes a trusted key using the given key_id."
        def delete_trusted_key(key_id)
          raise NotNexusProException unless nexus_remote.kind_of? ProRemote
          if nexus_remote.delete_trusted_key(key_id)
            say "The trusted key with an id of #{key_id} has been deleted.", :blue
          end
        end

        desc "get_trusted_keys", "Returns the trusted keys of the server."
        def get_trusted_keys
          raise NotNexusProException unless nexus_remote.kind_of? ProRemote
          say JSON.pretty_generate(JSON.parse(nexus_remote.get_trusted_keys)), :green
        end

        desc "get_license_info", "Returns the license information of the server."
        def get_license_info
          say nexus_remote.get_license_info, :green
        end

        desc "install_license license_file", "Installs a license file into the server."
        def install_license(license_file)
          nexus_remote.install_license(license_file)
        end

        desc "get_logging_info", "Gets the log4j Settings of the Nexus server."
        def get_logging_info
          say nexus_remote.get_logging_info, :green
        end

        desc "set_logger_level level", "Updates the log4j logging level to a new value."
        def set_logger_level(level)
          if nexus_remote.set_logger_level(level)
            say "The logging level of Nexus has been set to #{level.upcase}", :blue
          end
        end

        desc "create_group_repository name", "Creates a new repository group with the given name."
        def create_group_repository(name)
          if nexus_remote.create_group_repository(name)
            say "A new group repository named #{name} has been created.", :blue
          end
        end

        desc "get_group_repository group_id", "Gets information about the given group repository."
        def get_group_repository(group_id)
          say nexus_remote.get_group_repository(group_id), :green
        end

        desc "add_to_group_repository group_id repository_to_add_id", "Adds a repository with the given id into the group repository."
        def add_to_group_repository(group_id, repository_to_add_id)
          if nexus_remote.add_to_group_repository(group_id, repository_to_add_id)
            say "The repository #{repository_to_add_id} has been added to the repository group #{group_id}", :blue
          end
        end

        desc "remove_from_group_repository group_id repository_to_remove_id", "Remove a repository with the given id from the group repository."
        def remove_from_group_repository(group_id, repository_to_remove_id)
          if nexus_remote.remove_from_group_repository(group_id, repository_to_remove_id)
            say "The repository with an id of #{repository_to_remove_id} has been removed from the group repository, #{group_id}.", :blue
          end
        end

        desc "delete_group_repository group_id","Deletes a group repository based on the given id."
        def delete_group_repository(group_id)
          if nexus_remote.delete_group_repository(group_id)
            say "The group repository, #{group_id} has been deleted.", :blue
          end
        end

        desc "transfer_artifact artifact from_repository to_repository", "Transfers a given artifact from one repository to another."
        def transfer_artifact(artifact, from_repository, to_repository)
          if nexus_remote.transfer_artifact(artifact, from_repository, to_repository)
            say "The artifact #{artifact} has been transferred from #{from_repository} to #{to_repository}.", :blue
          end
        end

        private

          def nexus_remote
            begin
              nexus_remote ||= Factory.create(options[:overrides], options[:ssl_verify])
            rescue NexusCliError => e
              say e.message, :red
              exit e.status_code
            end
          end

          def ask_user(params, ask_username=true, ask_password=true)
            username = params[:username]
            first_name = params[:first_name]
            last_name = params[:last_name]
            email = params[:email]
            enabled = params[:enabled]
            password = params[:password]
            roles = params[:roles]
            status = enabled
            
            if username.nil? && ask_username
              username = ask "Please enter the username:" 
            end
            if first_name.nil?
              first_name = ask "Please enter the first name:"
            end
            if last_name.nil?
              last_name = ask "Please enter the last name:"
            end
            if email.nil?
              email = ask "Please enter the email:"
            end
            if enabled.nil?
              status = ask "Is this user enabled for use?", :limited_to => ["true", "false"]
            end
            if password.nil? && ask_password
              password = ask_password("Please enter a password:")
            end
            if roles.size == 0 
              roles = ask "Please enter the roles:"
            end
            params = {:userId => username}
            params[:firstName] = first_name
            params[:lastName] = last_name
            params[:email] = email
            params[:status] = status == true ? "active" : "disabled"
            params[:password] = password
            params[:roles] = roles.kind_of?(Array) ? roles : roles.split(' ')
            params
          end

          def ask_password(message)
            HighLine.new.ask(message) do |q| 
              q.echo = false
            end
          end
      end
    end
  end
end
