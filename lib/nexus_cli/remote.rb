require 'restclient'
require 'nokogiri'
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
        doc = Nokogiri::XML(nexus['service/local/status'].get).xpath("/status/data")
        data = Hash.new
        data['app_name'] = doc.xpath("appName")[0].text
        data['version'] = doc.xpath("version")[0].text
        data['edition_long'] = doc.xpath("editionLong")[0].text
        data['state'] = doc.xpath("state")[0].text
        data['started_at'] = doc.xpath("startedAt")[0].text
        data['base_url'] = doc.xpath("baseUrl")[0].text
        return data
      end

      def pull_artifact(artifact, destination, overrides)
        group_id, artifact_id, version, extension = parse_artifact_string(artifact)
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
        group_id, artifact_id, version, extension = parse_artifact_string(artifact)
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
        group_id, artifact_id, version = parse_artifact_string(artifact)
        delete_string = "content/repositories/releases/#{group_id.gsub(".", "/")}/#{artifact_id.gsub(".", "/")}/#{version}"
        Kernel.quietly {`curl --request DELETE #{File.join(configuration['url'], delete_string)} -u #{configuration['username']}:#{configuration['password']}`}
      end

      def get_artifact_info(artifact, overrides)
        group_id, artifact_id, version, extension = parse_artifact_string(artifact)
        begin
          nexus['service/local/artifact/maven/resolve'].get({:params => {:r => configuration['repository'], :g => group_id, :a => artifact_id, :v => version, :e => extension}})
        rescue RestClient::ResourceNotFound => e
          raise ArtifactNotFoundException
        end
      end
      
      def get_artifact_custom_info(artifact, overrides)
        raise NotNexusProException unless running_nexus_pro?
        parse_n3(get_artifact_custom_info_n3(artifact, overrides))
      end

      def get_artifact_custom_info_n3(artifact, overrides)
        group_id, artifact_id, version, extension = parse_artifact_string(artifact)
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
        group_id, artifact_id, version, extension = parse_artifact_string(artifact)
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
          nexus['service/local/search/m2/freeform'].get ({params: {p: key, t: type, v: value}}) do |response, request, result, &block|
            raise BadSearchRequestException if response.code == 400
            doc = Nokogiri::XML(response.body).xpath("/search-results")
            return doc.xpath("count")[0].text.to_i > 0 ? doc.to_s : "No search results."
          end
        rescue RestClient::ResourceNotFound => e
          raise ArtifactNotFoundException
        end
      end

      private
        def running_nexus_pro?
          return status['edition_long'] == "Professional" ? true : false
        end

        def parse_artifact_string(artifact)
          # The artifact string is in `groupdId:artifactId:version:extension` format.
          split_artifact = artifact.split(":")
          if(split_artifact.size < 4)
            raise ArtifactMalformedException
          end
          return split_artifact
        end

        def parse_n3(data)
          builder = Nokogiri::XML::Builder.new do |xml|
            xml.send("artifact-resolution") {
              xml.data {
                data.each_line { |line|
                  tag, value = parse_n3_line(line)
                  xml.send(tag, value) unless tag.empty? || value.empty?
                }
              }
            }
          end
          return builder.doc.root.to_s
        end

        def parse_n3_line(line)
            tag = line.match(/#(\w*)>/) ? "#{$1}" : ""
            value = line.match(/"([^"]*)"/)  ? "#{$1}" : ""
            return tag, value
        end
    end
  end
end
