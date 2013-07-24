require 'erb'
require 'tempfile'

module NexusCli
  # @author Kyle Allan <kallan@riotgames.com>
  module ArtifactActions
    
    # Retrieves a file from the Nexus server using the given [String] 
    # coordinates. Optionally provide a destination [String].
    #
    # @param [String] coordinates
    # @param [String] destination
    #
    # @return [Hash] Some information about the artifact that was pulled.
    def pull_artifact(coordinates, destination=nil)
      artifact = Artifact.new(coordinates)
      version = REXML::Document.new(get_artifact_info(coordinates)).elements["//version"].text if artifact.version.casecmp("latest")

      file_name = artifact.file_name
      destination = File.join(File.expand_path(destination || "."), file_name)
      query = {:g => artifact.group_id, :a => artifact.artifact_id, :e => artifact.extension, :v => artifact.version, :r => configuration['repository']}
      query.merge!({:c => artifact.classifier}) unless artifact.classifier.nil?
      response = nexus.get(nexus_url("service/local/artifact/maven/redirect"), :query => query)
      case response.status
      when 301, 307
        # Follow redirect and stream in chunks.
        artifact_file = File.open(destination, "wb") do |io|
          nexus.get(response.content.gsub(/If you are not automatically redirected use this url: /, "")) do |chunk|
            io.write(chunk)
          end
        end
      when 404
        raise ArtifactNotFoundException
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end
      {
        :file_name => file_name,
        :file_path => File.expand_path(destination),
        :version   => version,
        :size      => File.size(File.expand_path(destination))
      }
    end

    # Pushes the given [file] to the Nexus server
    # under the given [artifact] identifier.
    # 
    # @param  coordinates [String] the Maven identifier
    # @param  file [type] the path to the file
    # 
    # @return [Boolean] returns true when successful
    def push_artifact(coordinates, file)
      artifact = Artifact.new(coordinates)
      put_string = "content/repositories/#{configuration['repository']}/#{artifact.group_id.gsub(".", "/")}/#{artifact.artifact_id.gsub(".", "/")}/#{artifact.version}/#{artifact.file_name}"
      response = nexus.put(nexus_url(put_string), File.open(file))

      case response.status
      when 201
        pom_name = "#{artifact.artifact_id}-#{artifact.version}.pom"
        put_string = "content/repositories/#{configuration['repository']}/#{artifact.group_id.gsub(".", "/")}/#{artifact.artifact_id.gsub(".", "/")}/#{artifact.version}/#{pom_name}"
        pom_file = generate_fake_pom(pom_name, artifact)
        nexus.put(nexus_url(put_string), File.open(pom_file))
        delete_string = "/service/local/metadata/repositories/#{configuration['repository']}/content/#{artifact.group_id.gsub(".", "/")}/#{artifact.artifact_id.gsub(".", "/")}"
        nexus.delete(nexus_url(delete_string))
        return true
      when 400
        raise BadUploadRequestException
      when 401
        raise PermissionsException
      when 403
        raise PermissionsException
      when 404
        raise NexusHTTP404.new(response.content)
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end
    end

    def delete_artifact(coordinates)
      artifact = Artifact.new(coordinates)
      response = nexus.delete(nexus_url("content/repositories/#{configuration['repository']}/#{artifact.group_id.gsub(".", "/")}/#{artifact.artifact_id.gsub(".", "/")}/#{artifact.version}"))
      case response.status
      when 204
        return true
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end
    end


    # Retrieves information about the given [artifact] and returns
    # it in as a [String] of XML.
    # 
    # @param  coordinates [String] the Maven identifier
    # 
    # @return [String] A string of XML data about the desired artifact
    def get_artifact_info(coordinates)
      artifact = Artifact.new(coordinates)
      query = {:g => artifact.group_id, :a => artifact.artifact_id, :e => artifact.extension, :v => artifact.version, :r => configuration['repository']}
      query.merge!({:c => artifact.classifier}) unless artifact.classifier.nil?
      response = nexus.get(nexus_url("service/local/artifact/maven/resolve"), query)
      case response.status
      when 200
        return response.content
      when 404
        raise ArtifactNotFoundException
      when 503
        raise CouldNotConnectToNexusException
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end
    end


    # Searches for an artifact using the given identifier.
    #
    # @param  coordinates [String] the Maven identifier
    # @example com.artifact:my-artifact
    # 
    # @return [Array<String>] a formatted Array of results
    # @example 
    #   1.0.0     `nexus-cli pull com.artifact:my-artifact:tgz:1.0.0`
    #   2.0.0     `nexus-cli pull com.artifact:my-artifact:tgz:2.0.0`
    #   3.0.0     `nexus-cli pull com.artifact:my-artifact:tgz:3.0.0`
    def search_for_artifacts(coordinates)
      group_id, artifact_id = coordinates.split(":")
      response = nexus.get(nexus_url("service/local/data_index"), :query => {:g => group_id, :a => artifact_id})
      case response.status
      when 200
        doc = REXML::Document.new(response.content)
        return format_search_results(doc, group_id, artifact_id)
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end
    end

    def transfer_artifact(coordinates, from_repository, to_repository)
      do_transfer_artifact(coordinates, from_repository, to_repository)
    end

    private

    # Formats the given XML into an [Array<String>] so it
    # can be displayed nicely.
    # 
    # @param  doc [REXML::Document] the xml search results
    # @param  group_id [String] the group id
    # @param  artifact_id [String] the artifact id
    # 
    # @return [type] [description]
    def format_search_results(doc, group_id, artifact_id)
      
      versions = []
      REXML::XPath.each(doc, "//version") { |matched_version| versions << matched_version.text }
      if versions.length > 0
        indent_size = versions.max{|a,b| a.length <=> b.length}.size+4
        formated_results = ['Found Versions:']
        versions.inject(formated_results) do |array,version|
          temp_version = version + ":"
          array << "#{temp_version.ljust(indent_size)} `nexus-cli pull #{group_id}:#{artifact_id}:#{version}:tgz`"
        end
      else 
        formated_results = ['No Versions Found.']
      end 
    end

    # Transfers an artifact from one repository
    # to another. Sometimes called a `promotion`
    # 
    # @param  coordinates [String] a Maven identifier
    # @param  from_repository [String] the name of the from repository
    # @param  to_repository [String] the name of the to repository
    # 
    # @return [Boolean] returns true when successful
    def do_transfer_artifact(coordinates, from_repository, to_repository)
      Dir.mktmpdir do |temp_dir|
        configuration["repository"] = sanitize_for_id(from_repository)
        artifact_file = pull_artifact(coordinates, temp_dir)
        configuration["repository"] = sanitize_for_id(to_repository)
        push_artifact(coordinates, artifact_file[:file_path])
      end
    end

    def generate_fake_pom(pom_name, artifact)
      Tempfile.open(pom_name) do |file|
        template_path = File.join(NexusCli.root, "data", "pom.xml.erb")
        file.puts ERB.new(File.read(template_path)).result(binding)
        file
      end
    end
  end
end
