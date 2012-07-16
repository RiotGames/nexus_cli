require 'restclient'
require 'nokogiri'
require 'tempfile'
require 'yaml'

module NexusCli
  class ProRemote < OSSRemote
      
    def get_artifact_custom_info(artifact, overrides)
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