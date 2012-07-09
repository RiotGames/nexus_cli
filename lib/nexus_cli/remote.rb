require 'restclient'
require 'rexml/document'
require 'yaml'
require 'open3'

module NexusCli
  class Remote
    class << self

      def configuration=(config = {})
        @configuration = config
      end

      def configuration
        return @configuration if @configuration
      end

      def nexus
        @nexus ||= RestClient::Resource.new configuration["url"], :user => configuration["username"], :password => configuration["password"]
      end

      def status
        doc = REXML::Document.new(nexus['service/local/status'].get).elements['status/data']
        data = Hash.new
        data['app_name'] = doc.elements['appName'].text
        data['version'] = doc.elements['version'].text
        data['edition_long'] = doc.elements['editionLong'].text
        data['state'] = doc.elements['state'].text
        data['started_at'] = doc.elements['startedAt'].text
        data['base_url'] = doc.elements['baseUrl'].text
        return data
      end

      def pull_artifact(artifact, destination, overrides)
        split_artifact = artifact.split(":")
        if(split_artifact.size < 4)
          raise ArtifactMalformedException
        end
        group_id, artifact_id, version, extension = split_artifact
        begin
          fileData = nexus['service/local/artifact/maven/redirect'].get ({params: {r: configuration['repository'], g: group_id, a: artifact_id, v: version, e: extension}})
        rescue RestClient::ResourceNotFound
          raise ArtifactNotFoundException
        end
        artifact = nil
        destination = File.join(File.expand_path(destination || "."), "#{artifact_id}-#{version}.#{extension}")
        artifact = File.open(destination, 'w')
        artifact.write(fileData)
        artifact.close()
        File.expand_path(artifact.path)
      end

      def push_artifact(artifact, file, insecure, overrides)
        split_artifact = artifact.split(":")
        if(split_artifact.size < 4)
          raise ArtifactMalformedException
        end
        group_id, artifact_id, version, extension = split_artifact
        file_name = "#{artifact_id}-#{version}.#{extension}"      
        put_string = "content/repositories/#{configuration['repository']}/#{group_id.gsub(".", "/")}/#{artifact_id.gsub(".", "/")}/#{version}/#{file_name}"
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
        group_id = split_artifact[0].gsub(".", "/")
        artifact_id = split_artifact[1].gsub(".", "/")
        version = split_artifact[2]

        delete_string = "content/repositories/releases/#{group_id}/#{artifact_id}/#{version}"
        Kernel.quietly {`curl --request DELETE #{File.join(configuration['url'], delete_string)} -u #{configuration['username']}:#{configuration['password']}`}
      end

      def get_artifact_info(artifact, overrides)
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
      
      def get_artifact_custom_info(artifact, overrides)
        raise NotNexusProException unless running_nexus_pro?
        split_artifact = artifact.split(":")
        if(split_artifact.size < 4)
          raise ArtifactMalformedException
        end
        group_id, artifact_id, version, extension = split_artifact
        file_name = "#{artifact_id}-#{version}.#{extension}"      
        get_string = "content/repositories/#{configuration['repository']}/.meta/#{group_id.gsub(".", "/")}/#{artifact_id.gsub(".", "/")}/#{version}/#{file_name}.n3"
        begin
          n3_data = nexus[get_string].get
          parse_n3(n3_data)
        rescue RestClient::ResourceNotFound => e
          raise ArtifactNotFoundException
        end
      end

      private
        def running_nexus_pro?
          return status['edition_long'] == "Professional" ? true : false
        end

        def parse_n3(data)
          result = ""
          data.each_line { |item|
            tag = item.match(/#(\w*)>/) ? "#{$1}" : ""
            value = item.match(/"([^"]*)"/)  ? "#{$1}" : ""
            result += "    <#{tag}>#{value}</#{tag}>\n" unless tag.empty? && value.empty?
          }
          return "<artifact-resolution>\n  <data>\n" + result + "  </data>\n</artifact-resolution>"
        end
    end
  end
end