require 'json'

module NexusCli
  # @author Leo Simons <lsimons@schubergphilis.com>
  module RoleActions

    # Creates a role mapping that the Nexus uses to link external role providers (LDAP) to internal roles.
    # 
    # @param  name [String] the name of the role in the external provider (LDAP group name)
    # @param  roles [Array<String>] the ids of the nexus roles to apply to the external role (i.e. "nx-admin")
    # @param  privileges [Array<String>] the names of the nexus privileges to apply to the external role (i.e. "1000")
    # 
    # @return [Boolean] returns true on success
    def create_role_mapping(name, roles=[], privileges=[])
      json = role_mapping_json(name, roles, privileges)
      response = nexus.post(nexus_url("service/local/roles"), :body => json, :header => DEFAULT_CONTENT_TYPE_HEADER)
      case response.status
        when 200
          return true
        when 201
          return true
        when 400
          raise CreateRoleMappingException.new(response.content)
        when 503
          raise CouldNotConnectToNexusException
        else
          raise UnexpectedStatusCodeException.new(response.status)
      end
    end

    # Deletes the given role mapping
    # 
    # @param  name [String] the name of the role mapping to delete, transformed
    # into an id.
    # 
    # @return [Boolean] true if the role mapping is deleted, false otherwise.
    def delete_role_mapping(name)
      response = nexus.delete(nexus_url("service/local/roles/#{sanitize_for_id(name)}"))
      case response.status
        when 204
          return true
        when 404
          raise RoleMappingDoesNotExistException
        when 503
          raise CouldNotConnectToNexusException
        else
          raise UnexpectedStatusCodeException.new(response.status)
      end
    end

    # Find information about the role mapping with the given
    # [name].
    # 
    # @param  name [String] the name of the role mapping, transformed
    # into an id.
    # 
    # @return [String] A String of XML with information about the desired
    # repository.
    def get_role_mapping_info(name)
      response = nexus.get(nexus_url("service/local/roles/#{sanitize_for_id(name)}"), :header => DEFAULT_ACCEPT_HEADER)
      case response.status
        when 200
          return response.content
        when 404
          raise RoleMappingNotFoundException
        when 503
          raise CouldNotConnectToNexusException
        else
          raise UnexpectedStatusCodeException.new(response.status)
      end
    end

    # Update the roles and privileges for the role mapping with the given
    # [name].
    # 
    # @param  name [String] the name of the role mapping, transformed
    # into an id.
    # 
    # @return [Boolean] true if the role mapping is successfully updated, false otherwise
    def update_role_mapping(name, roles=[], privileges=[])
      json = role_mapping_json(name, privileges, roles)
      response = nexus.put(nexus_url("service/local/roles/#{sanitize_for_id(name)}"),
                           :body => json, :header => DEFAULT_CONTENT_TYPE_HEADER)
      case response.status
        when 200
          return true
        when 400
          raise RoleMappingNotFoundException
        when 503
          raise CouldNotConnectToNexusException
        else
          raise UnexpectedStatusCodeException.new(response.status)
      end
    end
  
    private
  
    def role_mapping_json(name, roles, privileges)
      params = {}
      params[:id] = name
      params[:name] = name
      params[:description] = "External mapping for #{name} (LDAP)"
      unless roles.nil?
        params[:roles] = roles
      end
      unless privileges.nil?
        params[:privileges] = privileges
      end
      JSON.dump(:data => params)
    end
  end
end
