require 'restclient'
require 'nokogiri'
require 'tempfile'
require 'yaml'

module NexusCli
  class ProRemote < OSSRemote

    def get_artifact_custom_info(artifact)
      return N3Metadata::n3_to_xml(get_artifact_custom_info_n3(artifact))
    end

    def get_artifact_custom_info_n3(artifact)
      group_id, artifact_id, version, extension = parse_artifact_string(artifact)
      get_string = N3Metadata::generate_n3_path(group_id, artifact_id, version, extension, configuration['repository'])
      begin
        n3 = nexus[get_string].get
        if !n3.match(/<urn:maven#deleted>/).nil?
          raise ArtifactNotFoundException
        else
          return n3
        end
      rescue RestClient::ResourceNotFound => e
        raise ArtifactNotFoundException
      end
    end

    def update_artifact_custom_info(artifact, *params)
      group_id, artifact_id, version, extension = parse_artifact_string(artifact)
      n3_user_urns = { "n3_header" => N3Metadata::generate_n3_header(group_id, artifact_id, version, extension) }.merge(N3Metadata::generate_n3_urns_from_hash(parse_update_params(*params)))

      n3_temp = Tempfile.new("nexus_n3")
      begin
        n3_temp.write(N3Metadata::parse_n3_hash(n3_user_urns))
        n3_temp.close
        update_artifact_custom_info_n3(artifact, n3_temp.path)
      ensure
        n3_temp.close
        n3_temp.unlink
      end
    end

    def update_artifact_custom_info_n3(artifact, file)
      # Check if artifact exists before posting custom metadata.
      get_artifact_info(artifact)
      # Update the custom metadata using the n3 file.
      group_id, artifact_id, version, extension = parse_artifact_string(artifact)
      post_string = N3Metadata::generate_n3_path(group_id, artifact_id, version, extension, configuration['repository'])

      # Get all the urn:nexus/user# keys and consolidate.
      # Read in nexus n3 file. If this is a newly-added artifact, there will be no n3 file so escape the exception.
      begin
        nexus_n3 = get_artifact_custom_info_n3(artifact)
      rescue ArtifactNotFoundException
        nexus_n3 = ""
      end

      # Read in local n3 file.
      local_n3 = File.open(file).read

      n3_user_urns = { "n3_header" => N3Metadata::generate_n3_header(group_id, artifact_id, version, extension) }
      # Get the nexus keys.
      n3_user_urns = N3Metadata::generate_n3_urns_from_n3(nexus_n3, n3_user_urns)
      # Get the local keys and update the nexus keys.
      n3_user_urns = N3Metadata::generate_n3_urns_from_n3(local_n3, n3_user_urns)
      n3_temp = Tempfile.new("nexus_n3")
      begin
        n3_temp.write(N3Metadata::parse_n3_hash(n3_user_urns))
        n3_temp.close
        nexus[post_string].put({:file => File.new(n3_temp.path)})
      ensure
        n3_temp.close
        n3_temp.unlink
      end
    end

    def clear_artifact_custom_info(artifact)
      get_artifact_info(artifact)
      group_id, artifact_id, version, extension = parse_artifact_string(artifact)
      post_string = N3Metadata::generate_n3_path(group_id, artifact_id, version, extension, configuration['repository'])
      n3_user_urns = { "n3_header" => N3Metadata::generate_n3_header(group_id, artifact_id, version, extension) }
      n3_temp = Tempfile.new("nexus_n3")
      begin
        n3_temp.write(N3Metadata::parse_n3_hash(n3_user_urns))
        n3_temp.close
        nexus[post_string].put({:file => File.new(n3_temp.path)})
      ensure
        n3_temp.close
        n3_temp.unlink
      end
    end

    def search_artifacts(*params)
      docs = Array.new
      parse_search_params(*params).each do |param|
        begin
          nexus['service/local/search/m2/freeform'].get(:params => {:p => param[0], :t => param[1], :v => param[2]}) do |response|
            raise BadSearchRequestException if response.code == 400
            docs.push(Nokogiri::XML(response.body).xpath("/search-results/data"))
          end
        rescue RestClient::ResourceNotFound => e
          raise ArtifactNotFoundException
        end
      end
      result = docs.inject(docs.first) {|memo,doc| get_common_artifact_set(memo, doc)}
      return result.nil? ? "" : result.to_xml(:indent => 4)
    end

    def get_pub_sub(repository_id)
      nexus["service/local/smartproxy/pub-sub/#{repository_id}"].get
    end

    def enable_artifact_publish(repository_id)
      params = {:repositoryId => repository_id}
      params[:publish] = true
      artifact_publish(repository_id, params)
    end

    def disable_artifact_publish(repository_id)
      params = {:repositoryId => repository_id}
      params[:publish] = false
      artifact_publish(repository_id, params)
    end

    def artifact_publish(repository_id, params)
      nexus["service/local/smartproxy/pub-sub/#{repository_id}"].put(create_pub_sub_json(params), :content_type => "application/json") do |response|
        case response.code
        when 200
          return true
        else
          raise UnexpectedStatusCodeException.new(response.code)
        end
      end
    end


    def enable_artifact_subscribe(repository_id)
      raise NotProxyRepositoryException.new(repository_id) unless Nokogiri::XML(get_repository_info(repository_id)).xpath("/repository/data/repoType").first.content == "proxy"

      params = {:repositoryId => repository_id}
      params[:subscribe] = true
      artifact_subscribe(repository_id, params)
    end

    def disable_artifact_subscribe(repository_id)
      raise NotProxyRepositoryException.new(repository_id) unless Nokogiri::XML(get_repository_info(repository_id)).xpath("/repository/data/repoType").first.content == "proxy"

      params = {:repositoryId => repository_id}
      params[:subscribe] = false
      artifact_subscribe(repository_id, params)
    end

    def artifact_subscribe(repository_id, params)
      nexus["service/local/smartproxy/pub-sub/#{repository_id}"].put(create_pub_sub_json(params), :content_type => "application/json") do |response|
        case response.code
        when 200
          return true
        else
          raise UnexpectedStatusCodeException.new(response.code)
        end
      end
    end

    def enable_smart_proxy(host=nil, port=nil)
      params = {:enabled => true}
      params[:host] = host unless host.nil?
      params[:port] = port unless port.nil?
      smart_proxy(params)
    end

    def disable_smart_proxy
      params = {:enabled => false}
      smart_proxy(params)
    end

    def smart_proxy(params)
      nexus["service/local/smartproxy/settings"].put(create_smart_proxy_settings_json(params), :content_type => "application/json") do |response|
        case response.code
        when 200
          return true
        else
          raise UnexpectedStatusCodeException.new(response.code)
        end
      end
    end

    def get_smart_proxy_settings
      nexus["service/local/smartproxy/settings"].get(:accept => "application/json")
    end

    def get_smart_proxy_key
      nexus["service/local/smartproxy/settings"].get(:accept => "application/json")
    end

    def add_trusted_key(certificate, description, path=true)
      params = {:description => description}
      params[:certificate] = path ? File.read(File.expand_path(certificate)) : certificate
      nexus["service/local/smartproxy/trusted-keys"].post(create_add_trusted_key_json(params), :content_type => "application/json") do |response|
        case response.code
        when 201
          return true
        else
          raise UnexpectedStatusCodeException.new(response.code)
        end
      end
    end

    def delete_trusted_key(key_id)
      nexus["service/local/smartproxy/trusted-keys/#{key_id}"].delete do |response|
        case response.code
        when 204
          return true
        else
          raise UnexpectedStatusCodeException.new(response.code)
        end
      end
    end

    def get_trusted_keys
      nexus["service/local/smartproxy/trusted-keys"].get(:accept => "application/json")
    end

    def get_license_info
      nexus["service/local/licensing"].get(:accept => "application/json")
    end

    def install_license(license_file)
      file = File.read(File.expand_path(license_file))
      nexus["service/local/licensing/upload"].post(file, :content_type => "application/octet-stream") do |response|
        case response.code
        when 201
          return true
        when 403
          raise LicenseInstallFailure
        else
          raise UnexpectedStatusCodeException.new(response.code)
        end
      end
    end

    def install_license_bytes(bytes)
      nexus["service/local/licensing/upload"].post(bytes, :content_type => "application/octet-stream") do |response|
        case response.code
        when 201
          return true
        when 403
          raise LicenseInstallFailure
        else
          raise UnexpectedStatusCodeException.new(response.code)
        end
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

      def parse_update_params(*params)
        begin
          parsed_params = Hash.new
          params.each do |param|
            # The first colon separates key and value.
            c1 = param.index(":")
            key = param[0..(c1 - 1)]
            value = param[(c1 + 1)..-1]
            !c1.nil? && N3Metadata::valid_n3_key?(key) && N3Metadata::valid_n3_value?(value) ? parsed_params[key] = value : raise
          end
          return parsed_params
        rescue
          raise N3ParameterMalformedException
        end
      end

      def parse_search_params(*params)
        begin
          parsed_params = Array.new
          params.each do |param|
            # The first two colons separate key, type, and value.
            c1 = param.index(":")
            c2 = param.index(":", (c1 + 1))
            key = param[0..(c1 - 1)]
            type = param[(c1 + 1)..(c2 - 1)]
            value = param[(c2 + 1)..-1]
            !c1.nil? && !c2.nil? && N3Metadata::valid_n3_key?(key) && N3Metadata::valid_n3_value?(value) && N3Metadata::valid_n3_search_type?(type) ? parsed_params.push([key, type, value]) : raise
          end
          return parsed_params
        rescue
          raise SearchParameterMalformedException
        end
      end

      # Expects the XML set with `data` as root.
      def get_common_artifact_set(set1, set2)
        intersection = get_artifact_array(set1) & get_artifact_array(set2)
        return intersection.count > 0 ? Nokogiri::XML("<data>#{intersection.join}</data>").root : Nokogiri::XML("").root
      end

      # Collect <artifact>...</artifact> elements into an array.
      # This will allow use of array intersection to find common artifacts in searches.
      def get_artifact_array(set)
        artifacts = Array.new
        artifact = nil
        set.to_s.split("\n").collect {|x| x.to_s.strip}.each do |piece|
          if piece == "<artifact>"
            artifact = piece
          elsif piece == "</artifact>"
            artifact += piece
            artifacts.push(artifact)
            artifact = nil
          elsif !artifact.nil?
            artifact += piece
          end
        end
        return artifacts
      end
  end
end
