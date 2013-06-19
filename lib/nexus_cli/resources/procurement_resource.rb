module NexusCli
  class ProcurementResource < NexusCli::Resource
    def start(repository, procured_from_repository)
      rest_request(:post, "procurement/manage", get_payload(repository, procured_from_repository))
    end

    def stop(repository)
      rest_request(:delete, "procurement/manage/#{repository}")
    end

    def add_rule(repository, rule)
      rest_request(:post, "procurement/resolutions/#{repository}", rule)
    end

    # Returns an Array of the current rules for the given
    # procurement repository.
    # 
    # @param  repository [String] the id of the repository
    # 
    # @return [Array<RuleOBject>] the applied procurement rules on this repository
    def rules(repository)
      response = rest_request(:get, "procurement/resolutions/#{repository}")
      response.data.collect { |rule| NexusCli::RuleObject.from_nexus_response(rule) }
    end

    private
      def get_payload(repository, procured_from_repository)
        json_payload = {"data" => {"repositoryId" => repository, "targetClassId" => "repositories", "targetId" => procured_from_repository}}
        JSON.dump(json_payload)
      end
  end
end
