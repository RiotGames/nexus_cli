require 'json'

module NexusCli
  # @author Kyle Allan <kallan@riotgames.com>
  module RepositoryActions
    
    # Creates a repository that the Nexus uses to hold artifacts.
    # 
    # @param  name [String] the name of the repository to create
    # @param  proxy [Boolean] true if this is a proxy repository
    # @param  url [String] the url for the proxy repository to point to
    # @param  id [String] the id of repository 
    # @param  policy [String] repository policy (RELEASE|SNAPSHOT)
    # @param  provider [String] repo provider (maven2 by default)
    # 
    # @return [Boolean] returns true on success
    def create_repository(name, proxy, url, id, policy, provider)
      json = if proxy
        create_proxy_repository_json(name, url, id, policy, provider)
      else
        create_hosted_repository_json(name, id, policy, provider)
      end
      response = nexus.post(nexus_url("service/local/repositories"), :body => json, :header => DEFAULT_CONTENT_TYPE_HEADER)
      case response.status
      when 201
        return true
      when 400
        raise CreateRepsitoryException.new(response.content)
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end
    end

    # Deletes the given repository
    # 
    # @param  name [String] the name of the repositroy to delete, transformed
    # into an id.
    # 
    # @return [Boolean] true if the repository is deleted, false otherwise.
    def delete_repository(name)
      response = nexus.delete(nexus_url("service/local/repositories/#{sanitize_for_id(name)}"))
      case response.status
      when 204
        return true
      when 404
        raise RepositoryDoesNotExistException
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end
    end

    # Find information about the repository with the given
    # [name].
    # 
    # @param  name [String] the name of the repository, transformed
    # into an id.
    # 
    # @return [String] A String of XML with information about the desired
    # repository.
    def get_repository_info(name)
      response = nexus.get(nexus_url("service/local/repositories/#{sanitize_for_id(name)}"))
      case response.status
      when 200
        return response.content
      when 404
        raise RepositoryNotFoundException
      when 503
        raise CouldNotConnectToNexusException
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end
    end

    # Creates a group repository with the given name.
    # 
    # @param  name [String] the name to give the new repository
    # @param  id [String] an alternative id to use for the new repository
    # @param  provider [String] the type of Maven provider for this repository
    # 
    # @return [Boolean] true if the group repository is created, false otherwise
    def create_group_repository(name, id, provider)
      response = nexus.post(nexus_url("service/local/repo_groups"), :body => create_group_repository_json(name, id, provider), :header => DEFAULT_CONTENT_TYPE_HEADER)
      case response.status
      when 201
        return true
      when 400
        raise CreateRepsitoryException.new(response.content)
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end
    end

    # Gets information about the given group repository with
    # the given [group_id].
    # 
    # @param  group_id [String] the id of the group repository to find
    # 
    # @return [String] a JSON String of information about the given group repository
    def get_group_repository(group_id)
      response = nexus.get(nexus_url("service/local/repo_groups/#{sanitize_for_id(group_id)}"), :header => DEFAULT_ACCEPT_HEADER)
      case response.status
      when 200
        return response.content
      when 404
        raise RepositoryNotFoundException
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end
    end

    # Checks if a the given [repository_to_check] is a member
    # of the given group repository - [group_ip].
    # 
    # @param  group_id [String] the group repository to look in
    # @param  repository_to_check [String] the repository that might be a member of the group
    # 
    # @return [Boolean] true if the [repository_to_check] is a member of group repository, false otherwise
    def repository_in_group?(group_id, repository_to_check)
      group_repository = JSON.parse(get_group_repository(group_id))
      repositories_in_group = group_repository["data"]["repositories"]

      repositories_in_group.find{|repository| repository["id"] == sanitize_for_id(repository_to_check)}
    end

    # Adds the given [repository_to_add_id] to the given group repository,
    # [group_id].
    # 
    # @param  group_id [String] the group repository to add to
    # @param  repository_to_add_id [String] the repository to added to the group
    # 
    # @return [Boolean] true if the repository is successfully added, false otherwise
    def add_to_group_repository(group_id, repository_to_add_id)
      raise RepositoryInGroupException if repository_in_group?(group_id, repository_to_add_id)
      response = nexus.put(nexus_url("service/local/repo_groups/#{sanitize_for_id(group_id)}"), :body => create_add_to_group_repository_json(group_id, repository_to_add_id), :header => DEFAULT_CONTENT_TYPE_HEADER)
      case response.status
      when 200
        return true
      when 400
        raise RepositoryNotFoundException
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end
    end

    # Removes the given [repository_to_remove_id] from the group repository,
    # [group_id].
    # 
    # @param  group_id [String] the group repository to remove from
    # @param  repository_to_remove_id [String] the repository to remove from the group
    # 
    # @return [Boolean] true if the repisotory is successfully remove, false otherwise
    def remove_from_group_repository(group_id, repository_to_remove_id)
      raise RepositoryNotInGroupException unless repository_in_group?(group_id, repository_to_remove_id)
      response = nexus.put(nexus_url("service/local/repo_groups/#{sanitize_for_id(group_id)}"), :body => create_remove_from_group_repository_json(group_id, repository_to_remove_id), :header => DEFAULT_CONTENT_TYPE_HEADER)
      case response.status
      when 200
        return true
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end
    end

    # Deletes the given group repository.
    # 
    # @param  group_id [String] the group repository to delete
    # 
    # @return [Boolean] true if the group repository is deleted, false otherwise
    def delete_group_repository(group_id)
      response = nexus.delete(nexus_url("service/local/repo_groups/#{sanitize_for_id(group_id)}"))
      case response.status
      when 204
        return true
      when 404
        raise RepositoryNotFoundException
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end
    end

    private

    def create_hosted_repository_json(name, id, policy, provider)
      params = {:provider => provider.nil? ? "maven2": provider}
      params[:providerRole] = "org.sonatype.nexus.proxy.repository.Repository"
      params[:exposed] = true
      params[:browseable] = true
      params[:indexable] = true
      params[:repoType] = "hosted"
      params[:repoPolicy] = policy.nil? ? "RELEASE" : ["RELEASE", "SNAPSHOT"].include?(policy) ? policy : "RELEASE" 
      params[:name] = name
      params[:id] = id.nil? ? sanitize_for_id(name) : sanitize_for_id(id)
      params[:format] = "maven2"
      JSON.dump(:data => params)
    end

    def create_proxy_repository_json(name, url, id, policy, provider)
      params = {:provider => provider.nil? ? "maven2" : provider}
      params[:providerRole] = "org.sonatype.nexus.proxy.repository.Repository"
      params[:exposed] = true
      params[:browseable] = true
      params[:indexable] = true
      params[:repoType] = "proxy"
      params[:repoPolicy] = policy.nil? ? "RELEASE" : ["RELEASE", "SNAPSHOT"].include?(policy) ? policy : "RELEASE" 
      params[:checksumPolicy] = "WARN"
      params[:writePolicy] = "READ_ONLY"
      params[:downloadRemoteIndexes] = true
      params[:autoBlockActive] = false
      params[:name] = name
      params[:id] = id.nil? ? sanitize_for_id(name) : sanitize_for_id(id)
      params[:remoteStorage] = {:remoteStorageUrl => url.nil? ? "http://change-me.com/" : url}
      JSON.dump(:data => params)
    end

    def create_group_repository_json(name, id, provider)
      params = {:id => id.nil? ? sanitize_for_id(name) : sanitize_for_id(id)}
      params[:name] = name
      params[:provider] = provider.nil? ? "maven2" : provider
      params[:exposed] = true
      JSON.dump(:data => params)
    end

    def create_add_to_group_repository_json(group_id, repository_to_add_id)
      group_repository_json = JSON.parse(get_group_repository(group_id))
      repositories = group_repository_json["data"]["repositories"]
      repositories << {:id => sanitize_for_id(repository_to_add_id)}
      params = {:repositories => repositories}
      params[:id] = group_repository_json["data"]["id"]
      params[:name] = group_repository_json["data"]["name"]
      params[:exposed] = group_repository_json["data"]["exposed"]
      JSON.dump(:data => params)
    end

    def create_remove_from_group_repository_json(group_id, repository_to_remove_id)
      group_repository_json = JSON.parse(get_group_repository(group_id))
      repositories = group_repository_json["data"]["repositories"]

      repositories.delete(repository_in_group?(group_id, repository_to_remove_id))
      
      params = {:repositories => repositories}
      params[:id] = group_repository_json["data"]["id"]
      params[:name] = group_repository_json["data"]["name"]
      JSON.dump(:data => params)
    end
  end
end