require 'httpclient'
require 'nokogiri'
require 'yaml'

module NexusCli
  class ProRemote < OSSRemote
    # Gets the custom metadata for an artifact
    # @param [String] artifact The GAVE string of the artifact
    # @result [String] The resulting custom metadata xml from the get operation
    def get_artifact_custom_info_raw(artifact)
      group_id, artifact_id, version, extension = parse_artifact_string(artifact)
      encoded_string = N3Metadata::create_base64_subject(group_id, artifact_id, version, extension)
      response = nexus.get(nexus_url("service/local/index/custom_metadata/#{configuration['repository']}/#{encoded_string}"))
      case response.status
      when 200
        if N3Metadata::missing_custom_metadata?(response.content)
          raise N3NotFoundException
        else
          return response.content
        end
      when 404
        raise ArtifactNotFoundException
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end
    end

    # Gets the custom metadata for an artifact in a simplified XML format
    # @param [String] artifact The GAVE string of the artifact
    # @result [String] The resulting custom metadata xml from the get operation
    def get_artifact_custom_info(artifact)
      N3Metadata::convert_result_to_simple_xml(get_artifact_custom_info_raw(artifact))
    end

    # Updates custom metadata for an artifact
    # @param [String] artifact The GAVE string of the artifact
    # @param [Array] *params The array of key:value strings
    # @result [Integer] The resulting exit code of the operation
    def update_artifact_custom_info(artifact, *params)
      target_n3 = parse_custom_metadata_update_params(*params)
      nexus_n3 = get_custom_metadata_hash(artifact)

      do_update_custom_metadata(artifact, nexus_n3, target_n3)
    end

    # Clears all custom metadata from an artifact
    # @param [String] The GAVE string of the artifact
    # @result [Integer] The resulting exit code of the operation
    def clear_artifact_custom_info(artifact)
      get_artifact_custom_info(artifact) # Check that artifact has custom metadata
      group_id, artifact_id, version, extension = parse_artifact_string(artifact)
      encoded_string = N3Metadata::create_base64_subject(group_id, artifact_id, version, extension)
      response = nexus.post(nexus_url("service/local/index/custom_metadata/#{configuration['repository']}/#{encoded_string}"), :body => create_custom_metadata_clear_json, :header => DEFAULT_CONTENT_TYPE_HEADER)
      case response.status
      when 201
        return true
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end
    end

    # Searches for artifacts using custom metadata
    # @param [Array] *params The array of key:type:value strings
    # @result [String] The resulting xml from the search
    def search_artifacts_custom(*params)
      nodesets = Array.new
      parse_custom_metadata_search_params(*params).each do |param|
        response = nexus.get(nexus_url("service/local/search/m2/freeform"), :query => {:p => param[0], :t => param[1], :v => param[2]})
        case response.status
        when 200
          nodesets.push(Nokogiri::XML(response.body).xpath("/search-results/data"))
        when 400
          raise BadSearchRequestException
        when 404
          raise ArtifactNotFoundException
        else
          raise UnexpectedStatusCodeException.new(response.status)
        end
      end
      # Perform array intersection across all NodeSets for the final common set.
      result = nodesets.inject(nodesets.first) {|memo, nodeset| get_common_artifact_set(memo, nodeset)}
      return result.nil? ? "" : result.to_xml(:indent => 4)
    end

    def get_pub_sub(repository_id)
      response = nexus.get(nexus_url("service/local/smartproxy/pub-sub/#{repository_id}"))
      case response.status
      when 200
        return response.content
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end
    end

    def enable_artifact_publish(repository_id)
      params = {:repositoryId => repository_id}
      params[:publish] = true
      artifact_publish(repository_id, params)
    end

    def disable_artifact_publish(repository_id)
      params = {:repositoryId => repository_id}
      params[:publish] = false
      artifact_publish(repository_id, params)
    end

    def artifact_publish(repository_id, params)
      response = nexus.put(nexus_url("service/local/smartproxy/pub-sub/#{sanitize_for_id(repository_id)}"), :body => create_pub_sub_json(params), :header => DEFAULT_CONTENT_TYPE_HEADER)
      case response.status
      when 200
        return true
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end
    end

    def enable_artifact_subscribe(repository_id, preemptive_fetch)
      raise NotProxyRepositoryException.new(repository_id) unless Nokogiri::XML(get_repository_info(repository_id)).xpath("/repository/data/repoType").first.content == "proxy"

      params = {:repositoryId => repository_id}
      params[:subscribe] = true
      params[:preemptiveFetch] = preemptive_fetch
      artifact_subscribe(repository_id, params)
    end

    def disable_artifact_subscribe(repository_id)
      raise NotProxyRepositoryException.new(repository_id) unless Nokogiri::XML(get_repository_info(repository_id)).xpath("/repository/data/repoType").first.content == "proxy"

      params = {:repositoryId => repository_id}
      params[:subscribe] = false
      artifact_subscribe(repository_id, params)
    end

    def artifact_subscribe(repository_id, params)
      response = nexus.put(nexus_url("service/local/smartproxy/pub-sub/#{sanitize_for_id(repository_id)}"), :body => create_pub_sub_json(params), :header => DEFAULT_CONTENT_TYPE_HEADER)
      case response.status
      when 200
        return true
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end
    end

    def enable_smart_proxy(host=nil, port=nil)
      params = {:enabled => true}
      params[:host] = host unless host.nil?
      params[:port] = port unless port.nil?
      smart_proxy(params)
    end

    def disable_smart_proxy
      params = {:enabled => false}
      smart_proxy(params)
    end

    def smart_proxy(params)
      response = nexus.put(nexus_url("service/local/smartproxy/settings"), :body => create_smart_proxy_settings_json(params), :header => DEFAULT_CONTENT_TYPE_HEADER)
      case response.status
      when 200
        return true
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end
    end

    def get_smart_proxy_settings
      response = nexus.get(nexus_url("service/local/smartproxy/settings"), :header => DEFAULT_ACCEPT_HEADER)
      case response.status
      when 200
        return response.content
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end
    end

    def get_smart_proxy_key
      response = nexus.get(nexus_url("service/local/smartproxy/settings"), :header => DEFAULT_ACCEPT_HEADER)
      case response.status
      when 200
        return response.content
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end
    end

    def add_trusted_key(certificate, description, path=true)
      params = {:description => description}
      params[:certificate] = path ? File.read(File.expand_path(certificate)) : certificate
      response = nexus.post(nexus_url("service/local/smartproxy/trusted-keys"), :body => create_add_trusted_key_json(params), :header => DEFAULT_CONTENT_TYPE_HEADER)
      case response.status
      when 201
        return true
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end
    end

    def delete_trusted_key(key_id)
      response = nexus.delete(nexus_url("service/local/smartproxy/trusted-keys/#{key_id}"))
      case response.status
      when 204
        return true
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end
    end

    def get_trusted_keys
      response = nexus.get(nexus_url("service/local/smartproxy/trusted-keys"), :header => DEFAULT_ACCEPT_HEADER)
      case response.status
      when 200
        return response.content
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end
    end

    def get_license_info
      response = nexus.get(nexus_url("service/local/licensing"), :header => DEFAULT_ACCEPT_HEADER)
      case response.status
      when 200
        return response.content
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end
    end

    def install_license(license_file)
      file = File.read(File.expand_path(license_file))
      response = nexus.post(nexus_url("service/local/licensing/upload"), :body => file, :header => {"Content-Type" => "application/octet-stream"})
      case response.status
      when 201
        return true
      when 403
        raise LicenseInstallFailure
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end
    end

    def install_license_bytes(bytes)
      response = nexus.post(nexus_url("service/local/licensing/upload"), :body => bytes, :header => {"Content-Type" => "application/octet-stream"})
      case response.status
      when 201
        return true
      when 403
        raise LicenseInstallFailure
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end
    end

    def transfer_artifact(artifact, from_repository, to_repository)
      do_transfer_artifact(artifact, from_repository, to_repository)
      
      configuration["repository"] = sanitize_for_id(from_repository)
      from_artifact_metadata = get_custom_metadata_hash(artifact)

      configuration["repository"] = sanitize_for_id(to_repository)
      to_artifact_metadata = get_custom_metadata_hash(artifact)

      do_update_custom_metadata(artifact, from_artifact_metadata, to_artifact_metadata)
    end

    private

    def get_custom_metadata_hash(artifact)
      begin
        N3Metadata::convert_result_to_hash(get_artifact_custom_info_raw(artifact))
      rescue N3NotFoundException
        Hash.new
      end
    end

    def do_update_custom_metadata(artifact, source_metadata, target_metadata)
      group_id, artifact_id, version, extension = parse_artifact_string(artifact)
      encoded_string = N3Metadata::create_base64_subject(group_id, artifact_id, version, extension)
      response = nexus.post(nexus_url("service/local/index/custom_metadata/#{configuration['repository']}/#{encoded_string}"), :body => create_custom_metadata_update_json(source_metadata, target_metadata), :header => DEFAULT_CONTENT_TYPE_HEADER)
      case response.code
      when 201
        return true
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end
    end

    def create_add_trusted_key_json(params)
      JSON.dump(:data => params)
    end

    def create_smart_proxy_settings_json(params)
      JSON.dump(:data => params)
    end

    def create_pub_sub_json(params)
      JSON.dump(:data => params)
    end

    # Converts an array of parameters used to update custom metadata
    # @param [Array] *params The array of key:value strings
    # @return [Hash] The resulting hash of parsed key:value items
    # @example
    #   parse_custom_metadata_update_params(["cookie:oatmeal raisin"]) #=> {"cookie"=>"oatmeal raisin"}
    def parse_custom_metadata_update_params(*params)
      params.inject({}) do |parsed_params, param|
        # param = key:value
        metadata_key, metadata_value = param.split(":", 2)
        if N3Metadata::valid_n3_key?(metadata_key) && N3Metadata::valid_n3_value?(metadata_value)
          parsed_params[metadata_key] = metadata_value
        else
          raise N3ParameterMalformedException
        end
        parsed_params
      end
    end

    # Converts an array of parameters used to search by custom metadata
    # @param [Array] *params The array of key:type:value strings
    # @result [Array] The resulting array of parsed key:type:value items
    # @example
    #   parse_custom_metadata_search_params(["cookie:matches:oatmeal raisin"]) #=> #=> [["cookie","matches","oatmeal raisin"]]
    def parse_custom_metadata_search_params(*params)
      params.inject([]) do |parsed_params, param|
        # param = key:type:value
        metadata_key, search_type, metadata_value = param.split(":", 3)
        if N3Metadata::valid_n3_key?(metadata_key) && N3Metadata::valid_n3_value?(metadata_value) && N3Metadata::valid_n3_search_type?(search_type)
          parsed_params.push([metadata_key, search_type, metadata_value])
        else
          raise SearchParameterMalformedException
        end
        parsed_params
      end
    end

    def create_custom_metadata_update_json(source, target)
      JSON.dump(:data => N3Metadata::create_metadata_hash(source, target))
    end

    def create_custom_metadata_clear_json
      JSON.dump(:data => {})
    end

    # Gets the intersection of two artifact arrays, returning the common set
    # @param [Array] set1, set2 The two Nokogiri::NodeSet objects to intersect
    # @result [Nokogiri::NodeSet] The resulting object generated from the array intersect
    def get_common_artifact_set(set1, set2)
      intersection = get_artifact_array(set1) & get_artifact_array(set2)
      return intersection.count > 0 ? Nokogiri::XML("<data>#{intersection.join}</data>").root : Nokogiri::XML("").root
    end

    # Collect <artifact> elements into an array
    # @info This will allow use of array intersection to find common artifacts in searches
    # @param [Nokogiri::NodeSet] set The object to be divided by <artifact> elements
    # @result [Array] The result array of artifact elements
    def get_artifact_array(set)
      set.search("//artifact").inject([]) do |artifacts, artifact|
        artifacts.push(artifact.to_s)
        artifacts
      end
    end
  end
end
