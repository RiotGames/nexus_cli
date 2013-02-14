module NexusCli
  # @author Kyle Allan <kallan@riotgames.com>
  module SmartProxyActions

    # Gets Smart Proxy related information about the
    # given [repository_id].
    # 
    # @param  repository_id [String] the repository to get information about
    # 
    # @return [String] a String of XML about the given repository
    def get_pub_sub(repository_id)
      response = nexus.get(nexus_url("service/local/smartproxy/pub-sub/#{repository_id}"))
      case response.status
      when 200
        return response.content
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end
    end

    # Enables artifact publishing for the given [repository_id].
    #
    # @param  repository_id [String] the repository to enable artifact publishing on
    # 
    # @return [Boolean] true if the artifact is now publishing artifacts, false otherwise
    def enable_artifact_publish(repository_id)
      params = {:repositoryId => repository_id}
      params[:publish] = true
      artifact_publish(repository_id, params)
    end

    # Disables artifact publishing for the given [repository_id].
    #
    # @param  repository_id [String] the repository to disable artifact publishing on
    # 
    # @return [Boolean] true if the artifact is now disabled for publishing artifacts, false otherwise
    def disable_artifact_publish(repository_id)
      params = {:repositoryId => repository_id}
      params[:publish] = false
      artifact_publish(repository_id, params)
    end

    # Enables artifact subscribing for the given [repository_id].
    #
    # @param  repository_id [String] the repository to enable artifact subscribe on
    # @param  preemptive_fetch [Boolean] true if the repository should prefetch artifacts, false otherwise
    # 
    # @return [Boolean] true if the repository is now subscribing, false otherwise
    def enable_artifact_subscribe(repository_id, preemptive_fetch)
      raise NotProxyRepositoryException.new(repository_id) unless is_proxy_repository?(get_repository_info(repository_id))

      params = {:repositoryId => repository_id}
      params[:subscribe] = true
      params[:preemptiveFetch] = preemptive_fetch
      artifact_subscribe(repository_id, params)
    end

    # Disables artifact subscribing for the given [repository_id].
    #
    # @param  repository_id [String] the repository to disable artifact subscribing on
    # 
    # @return [Boolean] true if the repository is disabled, false otherwise
    def disable_artifact_subscribe(repository_id)
      raise NotProxyRepositoryException.new(repository_id) unless is_proxy_repository?(get_repository_info(repository_id))

      params = {:repositoryId => repository_id}
      params[:subscribe] = false
      artifact_subscribe(repository_id, params)
    end

    # Enables Smart Proxy on the Nexus server.
    # 
    # @param  host=nil [String] an optional host to listen on for Smart Proxy
    # @param  port=nil [Fixnum] an optional port to listen on for Smart Proxy
    # 
    # @return [Boolean] true if Smart Proxy is enabled, false otherwise
    def enable_smart_proxy(host=nil, port=nil)
      params = {:enabled => true}
      params[:host] = host unless host.nil?
      params[:port] = port unless port.nil?
      smart_proxy(params)
    end

    # Disables Smart Proxy on the Nexus server.
    #
    # 
    # @return [Boolean] true if Smart Proxy is disabled, false otherwise
    def disable_smart_proxy
      params = {:enabled => false}
      smart_proxy(params)
    end


    # Gets the current Smart Proxy settings of the Nexus server.
    #
    # 
    # @return [String] a String of JSON with information about Smart Proxy
    def get_smart_proxy_settings
      response = nexus.get(nexus_url("service/local/smartproxy/settings"), :header => DEFAULT_ACCEPT_HEADER)
      case response.status
      when 200
        return response.content
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end
    end

    # @deprecated this method might not be used.
    def get_smart_proxy_key
      response = nexus.get(nexus_url("service/local/smartproxy/settings"), :header => DEFAULT_ACCEPT_HEADER)
      case response.status
      when 200
        return response.content
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end
    end

    # Adds a trusted key to Nexus for use with Smart Proxy. By default,
    # the [certificate] parameter will point to a path of a certificate file. As an
    # alternative, call with path=false to pass a certificate in directly.
    # 
    # @param  certificate [String] a path to or the actual certificate String
    # @param  description [String] a brief description of the key; usually the name of the server the key belongs to
    # @param  path=true [Boolean] by default uses [certificate] as a path to a file, when false, [certificate] is treated as a String
    # 
    # @return [Boolean] true when the certificate is added, false otherwise
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

    # Deletes a trusted key from the Nexus server. 
    #
    # @param  key_id [String] the key to delete
    # 
    # @return [Boolean] true if the key has been deleted, false otherwise
    def delete_trusted_key(key_id)
      response = nexus.delete(nexus_url("service/local/smartproxy/trusted-keys/#{key_id}"))
      case response.status
      when 204
        return true
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end
    end

    # Gets information about the current list of trusted keys
    # in the Nexus server. A large amount of JSON will be printed
    # because this resource returns the actual certificates.
    # 
    # @return [String] a String of JSON from Nexus about the current list of trusted keys
    def get_trusted_keys
      response = nexus.get(nexus_url("service/local/smartproxy/trusted-keys"), :header => DEFAULT_ACCEPT_HEADER)
      case response.status
      when 200
        return response.content
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end
    end

    private

    def create_add_trusted_key_json(params)
      JSON.dump(:data => params)
    end

    def create_smart_proxy_settings_json(params)
      JSON.dump(:data => params)
    end

    def create_pub_sub_json(params)
      JSON.dump(:data => params)
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

    def artifact_publish(repository_id, params)
      response = nexus.put(nexus_url("service/local/smartproxy/pub-sub/#{sanitize_for_id(repository_id)}"), :body => create_pub_sub_json(params), :header => DEFAULT_CONTENT_TYPE_HEADER)
      case response.status
      when 200
        return true
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end
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

    private
      def is_proxy_repository?(repository_xml)
        REXML::Document.new(repository_xml).elements["/repository/data/repoType"].text == "proxy"
      end
  end
end