require 'json'

module NexusCli
  # @author Ilja Bobkevic <ilja.bobkevic@gmail.com>
  module LdapActions

    # Set provided LDAP connection information
    #
    # @param  params [Hash] a Hash of parameters for connection information
    #
    # @return [Boolean] true if the connection information was set, false otherwise
    def set_ldap_connection_info(params)
      response = nexus.put(nexus_url("service/local/ldap/conn_info"), :body => create_data(params), :header => DEFAULT_CONTENT_TYPE_HEADER)
      case response.status
      when 200
        return true
      else
        raise UnexpectedStatusCodeException.new(reponse.code)
      end
    end

    # Set provided LDAP user and group configuration
    #
    # @param  params [Hash] a Hash of parameters for user and group configuration
    #
    # @return [Boolean] true if the user and group configuration was set, false otherwise
    def set_ldap_user_group_configuration(params)
      response = nexus.put(nexus_url("service/local/ldap/user_group_conf"), :body => create_data(params), :header => DEFAULT_CONTENT_TYPE_HEADER)
      case response.status
      when 200
        return true
      else
        raise UnexpectedStatusCodeException.new(reponse.code)
      end
    end

    private

    def create_data(params)
      JSON.dump(:data => params)
    end
  end
end
