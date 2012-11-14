module NexusCli
  class ProRemote < BaseRemote
    
    include ArtifactActions
    include CustomMetadataActions
    include GlobalSettingsActions
    include LoggingActions
    include RepositoryActions
    include SmartProxyActions
    include UserActions

    def get_license_info
      response = nexus.get(nexus_url("service/local/licensing"), :header => DEFAULT_ACCEPT_HEADER)
      case response.status
      when 200
        return response.content
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end
    end

    def install_license(license_file)
      file = File.read(File.expand_path(license_file))
      response = nexus.post(nexus_url("service/local/licensing/upload"), :body => file, :header => {"Content-Type" => "application/octet-stream"})
      case response.status
      when 201
        return true
      when 403
        raise LicenseInstallFailure
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end
    end

    def install_license_bytes(bytes)
      response = nexus.post(nexus_url("service/local/licensing/upload"), :body => bytes, :header => {"Content-Type" => "application/octet-stream"})
      case response.status
      when 201
        return true
      when 403
        raise LicenseInstallFailure
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end
    end

    def transfer_artifact(artifact, from_repository, to_repository)
      do_transfer_artifact(artifact, from_repository, to_repository)
      
      configuration["repository"] = sanitize_for_id(from_repository)
      from_artifact_metadata = get_custom_metadata_hash(artifact)

      configuration["repository"] = sanitize_for_id(to_repository)
      to_artifact_metadata = get_custom_metadata_hash(artifact)

      do_update_custom_metadata(artifact, from_artifact_metadata, to_artifact_metadata)
    end
  end
end