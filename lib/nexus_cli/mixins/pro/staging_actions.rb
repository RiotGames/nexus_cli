module NexusCli
  module StagingActions

    # Starts a new staging repository with the ruleset defined
    # by the given staging_profile_id
    #
    # @param staging_profile_id [String]
    #
    # @return [String] the repository id of the new staging repository
    def start(staging_profile_id = configuration['default_profile_id'], description = "Starting Repository")
      response = nexus.post(nexus_url("service/local/staging/profiles/#{staging_profile_id}/start"), :body => create_promote_request(description), :header => DEFAULT_CONTENT_TYPE_HEADER)
      case response.status
      when 201
        JSON.parse(response.body)["data"]["stagedRepositoryId"]
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end
    end

    # Closes the given staging repository
    #
    # @param  repository_id [String]
    # @param  description = "Closing Repository" [String]
    #
    # @return [Boolean]
    def close(repository_id, description = "Closing Repository")
      response = nexus.post(nexus_url("service/local/staging/bulk/close"), :body => staging_lifecycle_payload(repository_id, description), :header => DEFAULT_CONTENT_TYPE_HEADER)
      case response.status
      when 201
        true
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end
    end

    # Releases the given staging repository
    #
    #
    # @return [Bolean]
    def release
      response = nexus.post(nexus_url("service/local/staging/bulk/promote"), :body => staging_lifecycle_payload(repository_id, description), :header => DEFAULT_CONTENT_TYPE_HEADER)
      case response.status
      when 201
        true
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end
    end

    def profiles
      response = nexus.get(nexus_url("service/local/staging/profiles"))
      response.body
    end

    private

      def create_promote_request(description)
        json_payload = { "data" => { "description" => description } }
        JSON.dump(json_payload)
      end

      def staging_lifecycle_payload(repository_id, promotion_id = nil, description)
        json_payload = { "data" => { "stagedRepositoryIds" => Array(repository_id), "description" => description}}
        json_payload["stagingProfileGroup"] = promotion_id unless promotion_id.nil?
        JSON.dump(json_payload)
      end
  end
end
