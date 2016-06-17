require 'json'

module NexusCli
  # @author Kyle Allan <kallan@riotgames.com>
  module OssLdapSettingsActions

    # Retrieves the oss_ldap connection settings of the Nexus server
    #
    # @return [File] a File with the oss_ldap settings.
    def get_oss_ldap_conn_settings
      json = get_oss_ldap_conn_settings_json
      pretty_json = JSON.pretty_generate(JSON.parse(json))
      Dir.mkdir(File.expand_path("~/.nexus")) unless Dir.exists?(File.expand_path("~/.nexus"))
      destination = File.join(File.expand_path("~/.nexus"), "oss_ldap_conn_settings.json")
      artifact_file = File.open(destination, 'wb') do |file|
        file.write(pretty_json)
      end
    end

    def get_oss_ldap_conn_settings_json
      response = nexus.get(nexus_url("service/local/ldap/conn_info"), :header => DEFAULT_ACCEPT_HEADER)
      case response.status
      when 200
        return response.content
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end
    end

    def upload_oss_ldap_conn_settings(json=nil)
      oss_ldap_conn_settings = nil
      if json == nil
        oss_ldap_conn_settings = File.read(File.join(File.expand_path("~/.nexus"), "oss_ldap_conn_settings.json"))
      else
        oss_ldap_conn_settings = json
      end
      response = nexus.put(nexus_url("service/local/ldap/conn_info"), :body => oss_ldap_conn_settings, :header => DEFAULT_CONTENT_TYPE_HEADER)
      case response.status
      when 204
        return true
      when 400
        raise BadSettingsException.new(response.content)
      end
    end

    def reset_oss_ldap_conn_settings
      response = nexus.get(nexus_url("service/local/ldap/conn_info"), :header => DEFAULT_ACCEPT_HEADER)
      case response.status
      when 200
        default_json = response.content
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end

      response = nexus.put(nexus_url("service/local/ldap/conn_info"), :body => default_json, :header => DEFAULT_CONTENT_TYPE_HEADER)
      case response.status
      when 204
        return true
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end
    end

    # Retrieves the oss_ldap user and group settings of the Nexus server
    #
    # @return [File] a File with the oss_ldap settings.
    def get_oss_ldap_user_group_settings
      json = get_oss_ldap_user_group_settings_json
      pretty_json = JSON.pretty_generate(JSON.parse(json))
      Dir.mkdir(File.expand_path("~/.nexus")) unless Dir.exists?(File.expand_path("~/.nexus"))
      destination = File.join(File.expand_path("~/.nexus"), "oss_ldap_user_group_settings.json")
      artifact_file = File.open(destination, 'wb') do |file|
        file.write(pretty_json)
      end
    end

    def get_oss_ldap_user_group_settings_json
      response = nexus.get(nexus_url("service/local/ldap/user_group_conf"), :header => DEFAULT_ACCEPT_HEADER)
      case response.status
      when 200
        return response.content
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end
    end

    def upload_oss_ldap_user_group_settings(json=nil)
      oss_ldap_user_group_settings = nil
      if json == nil
        oss_ldap_user_group_settings = File.read(File.join(File.expand_path("~/.nexus"), "oss_ldap_user_group_settings.json"))
      else
        oss_ldap_user_group_settings = json
      end
      response = nexus.put(nexus_url("service/local/ldap/user_group_conf"), :body => oss_ldap_user_group_settings, :header => DEFAULT_CONTENT_TYPE_HEADER)
      case response.status
      when 204
        return true
      when 400
        raise BadSettingsException.new(response.content)
      end
    end

    def reset_oss_ldap_user_group_settings
      response = nexus.get(nexus_url("service/local/ldap/user_group_conf"), :header => DEFAULT_ACCEPT_HEADER)
      case response.status
      when 200
        default_json = response.content
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end

      response = nexus.put(nexus_url("service/local/ldap/user_group_conf"), :body => default_json, :header => DEFAULT_CONTENT_TYPE_HEADER)
      case response.status
      when 204
        return true
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end
    end

  end
end
