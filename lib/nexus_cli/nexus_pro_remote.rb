require 'restclient'
require 'nokogiri'
require 'tempfile'
require 'yaml'

module NexusCli
  class ProRemote < OSSRemote

    def get_artifact_custom_info(artifact)
      parse_n3(get_artifact_custom_info_n3(artifact))
    end

    def get_artifact_custom_info_n3(artifact)
      group_id, artifact_id, version, extension = parse_artifact_string(artifact)
      file_name = "#{artifact_id}-#{version}.#{extension}.n3"
      get_string = "content/repositories/#{configuration['repository']}/.meta/#{group_id.gsub(".", "/")}/#{artifact_id.gsub(".", "/")}/#{version}/#{file_name}"
      begin
        nexus[get_string].get
      rescue RestClient::ResourceNotFound => e
        raise ArtifactNotFoundException
      end
    end

    def update_artifact_custom_info(artifact, file)
      # Check if artifact exists before posting custom metadata.
      get_artifact_info(artifact)
      # Update the custom metadata using the n3 file.
      group_id, artifact_id, version, extension = parse_artifact_string(artifact)
      file_name = "#{artifact_id}-#{version}.#{extension}.n3"
      post_string = "content/repositories/#{configuration['repository']}/.meta/#{group_id.gsub(".", "/")}/#{artifact_id.gsub(".", "/")}/#{version}/#{file_name}"

      # Read in nexus n3 file. If this is a newly-added artifact, there will be no n3 file so escape the exception.
      begin
        nexus_n3 = get_artifact_custom_info_n3(artifact)
      rescue ArtifactNotFoundException
        nexus_n3 = ""
      end

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

    def clear_artifact_custom_info(artifact)
      # Check if artifact exists before posting custom metadata.
      get_artifact_info(artifact)
      group_id, artifact_id, version, extension = parse_artifact_string(artifact)
      file_name = "#{artifact_id}-#{version}.#{extension}.n3"
      post_string = "content/repositories/#{configuration['repository']}/.meta/#{group_id.gsub(".", "/")}/#{artifact_id.gsub(".", "/")}/#{version}/#{file_name}"
      n3_temp = Tempfile.new("nexus_n3")
      begin
        n3_temp.write("<urn:maven/artifact##{group_id}:#{artifact_id}:#{version}::#{extension}> a <urn:maven#artifact> .")
        n3_temp.rewind
        Kernel.quietly {`curl -T #{n3_temp.path} #{File.join(configuration['url'], post_string)} -u #{configuration['username']}:#{configuration['password']}`}
      ensure
        n3_temp.close
        n3_temp.unlink
      end
    end

    def search_artifacts(params)
      docs = Array.new
      parse_search_params(params).each { |param|
        begin
          nexus['service/local/search/m2/freeform'].get ({params: {p: param[0], t: param[1], v: param[2]}}) do |response|
            raise BadSearchRequestException if response.code == 400
            docs.push(Nokogiri::XML(response.body).xpath("/search-results/data"))
          end
        rescue RestClient::ResourceNotFound => e
          raise ArtifactNotFoundException
        end
      }
      result = docs.inject {|memo,doc| get_common_set(memo, doc)}
      return result.nil? ? "" : result.to_xml(:indent => 4)
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

    def parse_search_params(params)
      parsed_params = params.split(",").collect {|param| param.split(":")}
      parsed_params.each { |param|
        raise SearchParameterMalformedException unless param.count == 3
      }
      return parsed_params
    end

    def get_common_set(set1, set2)
      return Nokogiri::XML((set1.to_s.split("\n").collect {|x| x.to_s.strip} & set2.to_s.split("\n").collect {|x| x.to_s.strip}).join).root
    end
  end
end
