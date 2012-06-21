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
          raise MissingSettingsFile
        end
        validate_config(config)
        @configuration = config
      end

      def nexus
        @nexus ||= RestClient::Resource.new configuration["url"], :user => configuration["username"], :password => configuration["password"]
      end

      def pull_artifact(artifact, destination)
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

      def push_artifact(artifact, file, insecure)
        #Build up the pieces that will make up the PUT request
        split_artifact = artifact.split(":")
        if(split_artifact.size < 4)
          raise ArtifactMalformedException
        end
        artifact_id = split_artifact[0].gsub(".", "/")
        group_id = split_artifact[1].gsub(".", "/")
        version = split_artifact[2]
        file_name = "#{split_artifact[1]}-#{version}.#{split_artifact[3]}"      

        put_string = "content/repositories/releases/#{artifact_id}/#{group_id}/#{version}/#{file_name}"
        Open3.popen3("curl #{insecure ? "-k" : ""} -T #{file} #{configuration['url']}#{put_string} -u #{configuration['username']}:#{configuration['password']}") do |stdin, stdout, stderr, wait_thr|  
          exit_code = wait_thr.value.exitstatus
          case exit_code
          when 60
            raise NonSecureConnectionException
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
        Kernel.quietly {`curl --request DELETE #{configuration['url']}#{delete_string} -u #{configuration['username']}:#{configuration['password']}`}
      end

      def get_artifact_info(artifact)
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
    end
  end
end