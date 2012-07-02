require 'restclient'
require 'yaml'
require 'open3'

module NexusCli
  class Remote
    class << self

      def configuration=(config = {})
        validate_config(config)
        @configuration = config
      end

      def configuration
        return @configuration if @configuration
        begin
          config = YAML::load_file(File.expand_path("~/.nexus_cli"))
        rescue Errno::ENOENT
          raise MissingSettingsFileException
        end
        validate_config(config)
        @configuration = config
      end

      def nexus
        @nexus ||= RestClient::Resource.new configuration["url"], :user => configuration["username"], :password => configuration["password"]
      end

      def pull_artifact(artifact, destination, overrides)
        parse_overrides(overrides)
        split_artifact = artifact.split(":")
        if(split_artifact.size < 4)
          raise ArtifactMalformedException
        end
        begin
          fileData = nexus['service/local/artifact/maven/redirect'].get ({params: {r: configuration['repository'], g: split_artifact[0], a: split_artifact[1], v: split_artifact[2], e: split_artifact[3]}})
        rescue RestClient::ResourceNotFound
          raise ArtifactNotFoundException
        end
        artifact = nil
        destination = File.join(File.expand_path(destination || "."), "#{split_artifact[1]}-#{split_artifact[2]}.#{split_artifact[3]}")
        artifact = File.open(destination, 'w')
        artifact.write(fileData)
        artifact.close()
        File.expand_path(artifact.path)
      end

      def push_artifact(artifact, file, insecure, overrides)
        #Build up the pieces that will make up the PUT request
        parse_overrides(overrides)
        split_artifact = artifact.split(":")
        if(split_artifact.size < 4)
          raise ArtifactMalformedException
        end
        artifact_id = split_artifact[0].gsub(".", "/")
        group_id = split_artifact[1].gsub(".", "/")
        version = split_artifact[2]
        file_name = "#{split_artifact[1]}-#{version}.#{split_artifact[3]}"      
        repository = override_repository.nil? ? configuration['repository'] : override_repository
        put_string = "content/repositories/#{repository}/#{artifact_id}/#{group_id}/#{version}/#{file_name}"
        Open3.popen3("curl -I #{insecure ? "-k" : ""} -T #{file} #{File.join(configuration['url'], put_string)} -u #{configuration['username']}:#{configuration['password']}") do |stdin, stdout, stderr, wait_thr|  
          exit_code = wait_thr.value.exitstatus
          standard_out = stdout.read
          if (standard_out.match('403 Forbidden') || standard_out.match('401 Unauthorized'))
            raise PermissionsException
          elsif standard_out.match('400 Bad Request')
            raise BadUploadRequestException
          end
          case exit_code
          when 60
            raise NonSecureConnectionException
          when 7
            raise CouldNotConnectToNexusException
          end
        end
      end

      def delete_artifact(artifact)
        split_artifact = artifact.split(":")
        if(split_artifact.size < 4)
          raise ArtifactMalformedException
        end
        artifact_id = split_artifact[0].gsub(".", "/")
        group_id = split_artifact[1].gsub(".", "/")
        version = split_artifact[2]

        delete_string = "content/repositories/releases/#{artifact_id}/#{group_id}/#{version}"
        Kernel.quietly {`curl --request DELETE #{File.join(configuration['url'], delete_string)} -u #{configuration['username']}:#{configuration['password']}`}
      end

      def get_artifact_info(artifact, overrides)
        parse_overrides(overrides)
        split_artifact = artifact.split(":")
        if(split_artifact.size < 4)
          raise ArtifactMalformedException
        end
        begin
          nexus['service/local/artifact/maven/resolve'].get ({params: {r: configuration['repository'], g: split_artifact[0], a: split_artifact[1], v: split_artifact[2], e: split_artifact[3]}})
        rescue RestClient::ResourceNotFound => e
          raise ArtifactNotFoundException
        end
      end

      private

        def validate_config(configuration)
          ["url", "repository", "username","password"].each do |key|
            raise InvalidSettingsException.new(key) unless configuration.has_key?(key)
          end
        end

        def parse_overrides(overrides)
          overrides.each do |key, value|
            configuration[key] = value unless configuration[key].nil?
          end
        end
    end
  end
end