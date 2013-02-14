require 'erb'
require 'tempfile'

module NexusCli
  # @author Kyle Allan <kallan@riotgames.com>
  module ArtifactActions
    
    # Retrieves a file from the Nexus server using the given [String] artifact
    # identifier. Optionally provide a destination [String].
    #
    # @param [String] artifact
    # @param [String] destination
    #
    # @return [Hash] Some information about the artifact that was pulled.
    def pull_artifact(artifact, destination=nil)
      group_id, artifact_id, version, extension = parse_artifact_string(artifact)
      version = REXML::Document.new(get_artifact_info(artifact)).elements["//version"].text if version.casecmp("latest")

      file_name = "#{artifact_id}-#{version}.#{extension}"
      destination = File.join(File.expand_path(destination || "."), file_name)
      response = nexus.get(nexus_url("service/local/artifact/maven/redirect"), :query => {:g => group_id, :a => artifact_id, :v => version, :e => extension, :r => configuration['repository']})
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
    # @param  artifact [String] the Maven identifier
    # @param  file [type] the path to the file
    # 
    # @return [Boolean] returns true when successful
    def push_artifact(artifact, file)
      group_id, artifact_id, version, extension = parse_artifact_string(artifact)
      file_name = "#{artifact_id}-#{version}.#{extension}"
      put_string = "content/repositories/#{configuration['repository']}/#{group_id.gsub(".", "/")}/#{artifact_id.gsub(".", "/")}/#{version}/#{file_name}"
      response = nexus.put(nexus_url(put_string), File.open(file))

      case response.status
      when 201
        pom_name = "#{artifact_id}-#{version}.pom"
        put_string = "content/repositories/#{configuration['repository']}/#{group_id.gsub(".", "/")}/#{artifact_id.gsub(".", "/")}/#{version}/#{pom_name}"
        pom_file = generate_fake_pom(pom_name, group_id, artifact_id, version, extension)
        nexus.put(nexus_url(put_string), File.open(pom_file))
        delete_string = "/service/local/metadata/repositories/#{configuration['repository']}/content/#{group_id.gsub(".", "/")}/#{artifact_id.gsub(".", "/")}"
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

    def delete_artifact(artifact)
      group_id, artifact_id, version = parse_artifact_string(artifact)
      response = nexus.delete(nexus_url("content/repositories/#{configuration['repository']}/#{group_id.gsub(".", "/")}/#{artifact_id.gsub(".", "/")}/#{version}"))
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
    # @param  artifact [String] the Maven identifier
    # 
    # @return [String] A string of XML data about the desired artifact
    def get_artifact_info(artifact)
      group_id, artifact_id, version, extension = parse_artifact_string(artifact)
      response = nexus.get(nexus_url("service/local/artifact/maven/resolve"), :query => {:g => group_id, :a => artifact_id, :v => version, :e => extension, :r => configuration['repository']})
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
    # @param  artifact [String] the Maven identifier
    # @example com.artifact:my-artifact
    # 
    # @return [Array<String>] a formatted Array of results
    # @example 
    #   1.0.0     `nexus-cli pull com.artifact:my-artifact:1.0.0:tgz`
    #   2.0.0     `nexus-cli pull com.artifact:my-artifact:2.0.0:tgz`
    #   3.0.0     `nexus-cli pull com.artifact:my-artifact:3.0.0:tgz`
    def search_for_artifacts(artifact)
      group_id, artifact_id = artifact.split(":")
      response = nexus.get(nexus_url("service/local/data_index"), :query => {:g => group_id, :a => artifact_id})
      case response.status
      when 200
        doc = REXML::Document.new(response.content)
        return format_search_results(doc, group_id, artifact_id)
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end
    end

    def transfer_artifact(artifact, from_repository, to_repository)
      do_transfer_artifact(artifact, from_repository, to_repository)
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
    # @param  artifact [String] a Maven identifier
    # @param  from_repository [String] the name of the from repository
    # @param  to_repository [String] the name of the to repository
    # 
    # @return [Boolean] returns true when successful
    def do_transfer_artifact(artifact, from_repository, to_repository)
      Dir.mktmpdir do |temp_dir|
        configuration["repository"] = sanitize_for_id(from_repository)
        artifact_file = pull_artifact(artifact, temp_dir)
        configuration["repository"] = sanitize_for_id(to_repository)
        push_artifact(artifact, artifact_file[:file_path])
      end
    end

    def generate_fake_pom(pom_name, group_id, artifact_id, version, extension)
      Tempfile.open(pom_name) do |file|
        template_path = File.join(NexusCli.root, "data", "pom.xml.erb")
        file.puts ERB.new(File.read(template_path)).result(binding)
        file
      end
    end
  end
end