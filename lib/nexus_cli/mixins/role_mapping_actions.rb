require 'json'

module NexusCli
  # @author Ilja Bobkevic <ilja.bobkevic@gmail.com>
  module RoleMappingActions

    # Creates a User to role mapping within given source
    #
    # @param  params [Hash] a Hash of parameters to use during user to role mapping creation
    #
    # @return [Boolean] true if the user to role mapping is created, false otherwise
    def create_role_mapping(params)
      response = nexus.put(nexus_url("service/local/user_to_roles/#{params[:source]}/#{params[:userId]}"), :body => create_user_json(params), :header => DEFAULT_CONTENT_TYPE_HEADER)
      case response.status
      when 204
        return true
      when 404
        raise UserNotFoundException.new(params[:userId])
      else
        raise UnexpectedStatusCodeException.new(reponse.code)
      end
    end

    # Deletes the Nexus user to role mapping from define source and with the given user id.
    #
    # @param  realm [String] the mapping realm, e.g. LDAP
    # @param  user_id [String] the Nexus user to role mapping to delete
    #
    # @return [Boolean] true if the user to role mapping is deleted, false otherwise
    def delete_role_mapping(realm, mapping_id)
      response = nexus.delete(nexus_url("service/local/user_to_roles/#{realm}/#{mapping_id}"))
      case response.status
      when 204
        return true
      when 404
        raise UserNotFoundException.new(mapping_id)
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end
    end

    private

    def create_user_json(params)
      JSON.dump(:data => params)
    end
  end
end
