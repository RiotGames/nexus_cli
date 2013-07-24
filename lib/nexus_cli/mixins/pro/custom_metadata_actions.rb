module NexusCli
  # @author Kyle Allan <kallan@riotgames.com>
  module CustomMetadataActions

    # Gets the custom metadata for an artifact
    # @param [String] coordinates The GAVE string of the artifact
    # @result [String] The resulting custom metadata xml from the get operation
    def get_artifact_custom_info_raw(coordinates)
      artifact = Artifact.new(coordinates)
      encoded_string = N3Metadata::create_base64_subject(artifact)
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
    # @param [String] coordinates The GAVE string of the artifact
    # @result [String] The resulting custom metadata xml from the get operation
    def get_artifact_custom_info(coordinates)
      N3Metadata::convert_result_to_simple_xml(get_artifact_custom_info_raw(coordinates))
    end

    # Updates custom metadata for an artifact
    # @param [String] coordinates The GAVE string of the artifact
    # @param [Array] *params The array of key:value strings
    # @result [Integer] The resulting exit code of the operation
    def update_artifact_custom_info(coordinates, *params)
      target_n3 = parse_custom_metadata_update_params(*params)
      nexus_n3 = get_custom_metadata_hash(coordinates)

      do_update_custom_metadata(coordinates, nexus_n3, target_n3)
    end

    # Clears all custom metadata from an artifact
    # @param [String] The GAVE string of the artifact
    # @result [Integer] The resulting exit code of the operation
    def clear_artifact_custom_info(coordinates)
      get_artifact_custom_info(coordinates) # Check that artifact has custom metadata
      artifact = Artifact.new(coordinates)
      encoded_string = N3Metadata::create_base64_subject(artifact)
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
          nodesets.push(REXML::Document.new(response.body).elements["/search-results/data"])
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
      formatter = REXML::Formatters::Pretty.new(4)
      formatter.compact = true
      return result.nil? ? "" : formatter.write(result, "")
    end

    private

    def get_custom_metadata_hash(coordinates)
      begin
        N3Metadata::convert_result_to_hash(get_artifact_custom_info_raw(coordinates))
      rescue N3NotFoundException
        Hash.new
      end
    end

    def do_update_custom_metadata(coordinates, source_metadata, target_metadata)
      artifact = Artifact.new(coordinates)
      encoded_string = N3Metadata::create_base64_subject(artifact)
      response = nexus.post(nexus_url("service/local/index/custom_metadata/#{configuration['repository']}/#{encoded_string}"), :body => create_custom_metadata_update_json(source_metadata, target_metadata), :header => DEFAULT_CONTENT_TYPE_HEADER)
      case response.code
      when 201
        return true
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end
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
    #
    # @param [REXML::Document] left_document, right_document 
    #   The two REXML::Document objects to intersect
    #
    # @result [REXML::Document nil] 
    #   The resulting object generated from the intersectection or nil
    def get_common_artifact_set(left_document, right_document)
      intersection = get_artifact_array(left_document) & get_artifact_array(right_document)
      return intersection.count > 0 ? REXML::Document.new("<data>#{intersection.join}</data>").root : nil
    end

    # Collect <artifact> elements into an array
    # 
    # @info This will allow use of array intersection to find common artifacts in searches
    # 
    # @param [REXML::Document] document The object to be divided by <artifact> elements
    # 
    # @result [Array<String>] The result array of artifact elements
    def get_artifact_array(document)
      artifacts = []
      REXML::XPath.each(document, "//artifact") { |matched_artifact| artifacts << matched_artifact.text }
      artifacts
    end
  end
end
