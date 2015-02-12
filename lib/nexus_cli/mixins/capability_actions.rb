require 'json'

module NexusCli
  # @author Jonathan Morley <jmorley@cvent.com>
  module CapabilityActions

    # Creates a capability that Nexus uses.
    #
    # @param  type [String] the typeId of the capability to create
    # @param  enabled [Boolean] true if this capability is enabled
    # @param  properties [Hash] hash of the properties for the capability
    #
    # @return [Int] returns id of the  on success
    def create_capability(type, enabled, properties)
      json = create_capability_json(type, enabled, properties)
      response = nexus.post(nexus_url("service/siesta/capabilities"), :body => json, :header => DEFAULT_CONTENT_TYPE_HEADER)
      case response.status
      when 200
        return JSON.parse(response.content)["capability"]["id"]
      when 400
        raise CreateCapabilityException.new(response.content)
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end
    end

    # Deletes the given capability
    #
    # @param  id [Int] the id of the capability to delete.
    #
    # @return [Boolean] true if the capability is deleted, false otherwise.
    def delete_capability(id)
      response = nexus.delete(nexus_url("service/siesta/capabilities/#{id}"))
      case response.status
      when 204
        return true
      when 404
        raise CapabilityDoesNotExistException
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end
    end

    # Find information about the capability with the given [id].
    #
    # @param  id [Int] the id of the capability.
    #
    # @return [Hash] A Ruby hash with information about the desired capability.
    def get_capability_info(id)
      response = nexus.get(nexus_url("service/siesta/capabilities/#{id}"), :header => DEFAULT_ACCEPT_HEADER)
      case response.status
      when 200
        return JSON.parse(response.content)
      when 404
        raise CapabilityNotFoundException
      when 503
        raise CouldNotConnectToNexusException
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end
    end

    # Get information about all capabilities.
    #
    # @return [Hash] A Ruby hash with information about all capabilities.
    def get_capabilities_info()
      response = nexus.get(nexus_url("service/siesta/capabilities"), :header => DEFAULT_ACCEPT_HEADER)
      case response.status
      when 200
        return JSON.parse(response.content)
      when 503
        raise CouldNotConnectToNexusException
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end
    end

    private

    def create_capability_json(type, enabled, properties)
      params = {
          :typeId => type,
          :enabled => enabled.nil? ? true : enabled,
          :properties => properties.collect{|k,v| {:key => k, :value => v} }
      }
      JSON.dump(params)
    end
  end
end
