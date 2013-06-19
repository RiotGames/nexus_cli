module NexusCli
  class StagingResource < NexusCli::Resource

    # Uploads an artifact to either the default deploy path or to a specific staging
    # repository, depending on the provided repository_id
    #
    # @param  artifact_id [String] a colon-separated Nexus artifact identifier
    # @param  repository_id = nil [String] optional repository to upload to
    # @param  file [String] a path to the file to upload
    # 
    # @return [type] [description]
    def upload(artifact_id, repository_id = nil, file)
      repository_path = repository_path_for(artifact_id)
      file_name = file_name_for(artifact_id)

      if repository_id.nil?
        success = rest_request(:put, "staging/deploy/maven2/#{repository_path}/#{file_name}", File.read(File.expand_path(file)))
      else
        rest_request(:put, "staging/deployByRepositoryId/#{repository_id}/#{repository_path}/#{file_name}", File.read(File.expand_path(file)))
      end
    end

    def close(repository_id, description = "Closing Repository")
      rest_request(:post, "staging/bulk/close", get_payload(repository_id, description))
    end

    def drop(repository_id, description = "Dropping Repository")
      rest_request(:post, "staging/bulk/drop", get_payload(repository_id, description))
    end

    def promote(repository_id, promotion_id, description = "Promoting Repository")
      rest_request(:post, "staging/bulk/promote", get_payload(repository_id, promotion_id, description))
    end

    # Returns an Array of the current Staging Profiles on the Nexus
    # server.
    #
    # @return [Array<StagingProfileObject] the current set
    # of staging repository profiles on the Nexus server
    def profiles
      response = rest_request(:get, "staging/profiles")
      response.data.collect { |profile| NexusCli::StagingProfileObject.from_nexus_response(profile) }
    end

    def create_profile(profile)
      rest_request(:post, "staging/profiles", profile)
    end

    private
      def get_payload(repository_id, promotion_id = nil, description)
        json_payload = {"data" => {"stagedRepositoryIds" => Array(repository_id),"description" => description}}
        json_payload["stagingProfileGroup"] = promotion_id unless promotion_id.nil?
        JSON.dump(json_payload)
      end
  end
end
