require 'json'

module NexusCli
  # @author Kyle Allan <kallan@riotgames.com>
  module GlobalSettingsActions
    
    # Retrieves the global settings of the Nexus server
    # 
    # @return [File] a File with the global settings.
    def get_global_settings
      json = get_global_settings_json
      pretty_json = JSON.pretty_generate(JSON.parse(json))
      Dir.mkdir(File.expand_path("~/.nexus")) unless Dir.exists?(File.expand_path("~/.nexus"))
      destination = File.join(File.expand_path("~/.nexus"), "global_settings.json")
      artifact_file = File.open(destination, 'wb') do |file|
        file.write(pretty_json)
      end
    end

    def get_global_settings_json
      response = nexus.get(nexus_url("service/local/global_settings/current"), :header => DEFAULT_ACCEPT_HEADER)
      case response.status
      when 200
        return response.content
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end
    end

    def upload_global_settings(json=nil)
      global_settings = nil
      if json == nil
        global_settings = File.read(File.join(File.expand_path("~/.nexus"), "global_settings.json"))
      else
        global_settings = json
      end
      response = nexus.put(nexus_url("service/local/global_settings/current"), :body => global_settings, :header => DEFAULT_CONTENT_TYPE_HEADER)
      case response.status
      when 204
        return true
      when 400
        raise BadSettingsException.new(response.content)
      end
    end

    def reset_global_settings
      response = nexus.get(nexus_url("service/local/global_settings/default"), :header => DEFAULT_ACCEPT_HEADER)
      case response.status
      when 200
        default_json = response.content
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end

      response = nexus.put(nexus_url("service/local/global_settings/current"), :body => default_json, :header => DEFAULT_CONTENT_TYPE_HEADER)
      case response.status
      when 204
        return true
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end
    end
  end
end