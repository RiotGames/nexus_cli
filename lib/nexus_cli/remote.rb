require 'restclient'
require 'rexml/document'
require 'tempfile'
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
          fileData = nexus['service/local/artifact/maven/redirect'].get({:params => {:r => configuration['repository'], :g => group_id, :a => artifact_id, :v => version, :e => extension}})
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
        nexus['service/local/artifact/maven/content'].post({:hasPom => false, :g => group_id, :a => artifact_id, :v => version, :e => extension, :p => extension, :r => configuration['repository'],
          :file => File.new(file)}) do |response, request, result, &block|
          case response.code
          when 400
            raise BadUploadRequestException
          when 401
            raise PermissionsException
          when 403
            raise PermissionsException
          when 404
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
          nexus['service/local/artifact/maven/resolve'].get({:params => {:r => configuration['repository'], :g => split_artifact[0], :a => split_artifact[1], :v => split_artifact[2], :e => split_artifact[3]}})
        rescue RestClient::ResourceNotFound => e
          raise ArtifactNotFoundException
        end
      end
      
      def get_artifact_custom_info(artifact, overrides)
        raise NotNexusProException unless running_nexus_pro?
        parse_n3(get_artifact_custom_info_n3(artifact, overrides))
      end

      def get_artifact_custom_info_n3(artifact, overrides)
        raise NotNexusProException unless running_nexus_pro?
        split_artifact = artifact.split(":")
        if(split_artifact.size < 4)
          raise ArtifactMalformedException
        end
        group_id, artifact_id, version, extension = split_artifact
        file_name = "#{artifact_id}-#{version}.#{extension}.n3"      
        get_string = "content/repositories/#{configuration['repository']}/.meta/#{group_id.gsub(".", "/")}/#{artifact_id.gsub(".", "/")}/#{version}/#{file_name}"
        begin
          nexus[get_string].get
        rescue RestClient::ResourceNotFound => e
          raise ArtifactNotFoundException
        end
      end

      def update_artifact_custom_info(artifact, file, insecure, overrides)
        raise NotNexusProException unless running_nexus_pro?
        # Check if artifact exists before posting custom metadata.
        get_artifact_info(artifact, overrides)
        # Update the custom metadata using the n3 file.
        split_artifact = artifact.split(":")
        if(split_artifact.size < 4)
          raise ArtifactMalformedException
        end
        group_id, artifact_id, version, extension = split_artifact
        file_name = "#{artifact_id}-#{version}.#{extension}.n3"
        post_string = "content/repositories/#{configuration['repository']}/.meta/#{group_id.gsub(".", "/")}/#{artifact_id.gsub(".", "/")}/#{version}/#{file_name}"
        
        # Read in nexus n3 file.
        nexus_n3 = get_artifact_custom_info_n3(artifact, overrides)
        # Read in local n3 file.
        local_n3 = File.open(file).read

        n3_user_urns = { "head" => "<urn:maven/artifact##{group_id}:#{artifact_id}:#{version}::#{extension}> a <urn:maven#artifact>" }
        # Get all the urn:nexus/user# keys and consolidate.
        # First, get the nexus keys.
        nexus_n3.each_line { |line|
          if line.match(/urn:nexus\/user#/)
            tag, value = parse_n3_line(line)
            n3_user_urns[tag] = "\t<urn:nexus/user##{tag}> \"#{value}\"" unless tag.empty? || value.empty?
          end
        }
        # Next, get the local keys and update the nexus keys.
        local_n3.each_line { |line|
          if line.match(/urn:nexus\/user#/)
            tag, value = parse_n3_line(line)
            # Delete the nexus key if the local key has no value.
            if n3_user_urns.has_key?(tag) && value.empty?
              n3_user_urns.delete(tag)
            else
              n3_user_urns[tag] = "\t<urn:nexus/user##{tag}> \"#{value}\"" unless tag.empty? || value.empty?
            end
          end
        }

        n3_data = n3_user_urns.values.join(" ;\n") + " ."
        n3_temp = Tempfile.new("nexus_n3")
        begin
          n3_temp.write(n3_data)
          n3_temp.rewind
          Kernel.quietly {`curl -T #{n3_temp.path} #{File.join(configuration['url'], post_string)} -u #{configuration['username']}:#{configuration['password']}`}
        ensure
          n3_temp.close
          n3_temp.unlink
        end
      end

      def search_artifacts(key, type, value, overrides)
        raise NotNexusProException unless running_nexus_pro?
        if key.empty? || type.empty? || value.empty?
            raise SearchParameterMalformedException
        end
        begin
          doc = REXML::Document.new(nexus['service/local/search/m2/freeform'].get ({params: {p: key, t: type, v: value}})).elements['search-results']
          if doc.elements["count"].text.to_i > 0
            return doc
          else
            return "No search results."
          end
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
          data.each_line { |line|
            tag, value = parse_n3_line(line)
            result += "\t\t<#{tag}>#{value}</#{tag}>\n" unless tag.empty? || value.empty?
          }
          return "<artifact-resolution>\n\t<data>\n#{result}\t</data>\n</artifact-resolution>"
        end

        def parse_n3_line(line)
            tag = line.match(/#(\w*)>/) ? "#{$1}" : ""
            value = line.match(/"([^"]*)"/)  ? "#{$1}" : ""
            return tag, value
        end
    end
  end
end
