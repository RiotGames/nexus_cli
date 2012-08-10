require 'restclient'
require 'nokogiri'
require 'yaml'
require 'json'

module NexusCli
  class OSSRemote

    def initialize(overrides)
      @configuration = Configuration::parse(overrides)
    end

    def configuration
      return @configuration if @configuration
    end

    def nexus
      @nexus ||= RestClient::Resource.new configuration["url"], :user => configuration["username"], :password => configuration["password"], :timeout => 1000000, :open_timeout => 1000000
    end

    def status
      doc = Nokogiri::XML(nexus['service/local/status'].get).xpath("/status/data")
      data = Hash.new
      data['app_name'] = doc.xpath("appName")[0].text
      data['version'] = doc.xpath("version")[0].text
      data['edition_long'] = doc.xpath("editionLong")[0].text
      data['state'] = doc.xpath("state")[0].text
      data['started_at'] = doc.xpath("startedAt")[0].text
      data['base_url'] = doc.xpath("baseUrl")[0].text
      return data
    end

    def pull_artifact(artifact, destination)
      group_id, artifact_id, version, extension = parse_artifact_string(artifact)
      begin
        fileData = nexus['service/local/artifact/maven/redirect'].get({:params => {:r => configuration['repository'], :g => group_id, :a => artifact_id, :v => version, :e => extension}})
      rescue RestClient::ResourceNotFound
        raise ArtifactNotFoundException
      end
      if version.casecmp("latest")
        doc = Nokogiri::XML(get_artifact_info(artifact))
        version = doc.xpath("//version").first.content()
      end
      destination = File.join(File.expand_path(destination || "."), "#{artifact_id}-#{version}.#{extension}")
      artifact_file = File.open(destination, 'wb')
      artifact_file.write(fileData)
      artifact_file.close()
      File.expand_path(artifact_file.path)
    end

    def push_artifact(artifact, file)
      group_id, artifact_id, version, extension = parse_artifact_string(artifact)
      nexus['service/local/artifact/maven/content'].post({:hasPom => false, :g => group_id, :a => artifact_id, :v => version, :e => extension, :p => extension, :r => configuration['repository'],
      :file => File.new(file)}) do |response|
        case response.code
        when 400
          raise BadUploadRequestException
        when 401
          raise PermissionsException
        when 403
          raise PermissionsException
        when 404
          raise CouldNotConnectToNexusException
        end
      end
    end

    def delete_artifact(artifact)
      group_id, artifact_id, version = parse_artifact_string(artifact)
      delete_string = "content/repositories/releases/#{group_id.gsub(".", "/")}/#{artifact_id.gsub(".", "/")}/#{version}"
      Kernel.quietly {`curl --request DELETE #{File.join(configuration['url'], delete_string)} -u #{configuration['username']}:#{configuration['password']}`}
    end

    def get_artifact_info(artifact)
      group_id, artifact_id, version, extension = parse_artifact_string(artifact)
      begin
        nexus['service/local/artifact/maven/resolve'].get({:params => {:r => configuration['repository'], :g => group_id, :a => artifact_id, :v => version, :e => extension}})
      rescue Errno::ECONNREFUSED => e
        raise CouldNotConnectToNexusException
      rescue RestClient::ResourceNotFound => e
        raise ArtifactNotFoundException
      end
    end

    def search_for_artifacts(artifact)
      group_id, artifact_id = artifact.split(":")
      nexus['service/local/data_index'].get({:params => {:g => group_id, :a => artifact_id}}) do |response|
        doc = Nokogiri::XML(response.body)
        return format_search_results(doc, group_id, artifact_id)
      end
    end

    def get_global_settings
      nexus['service/local/global_settings/current'].get({:accept => "application/json"}) do |response|
        pretty_json = JSON.pretty_generate(JSON.parse(response.body))
        destination = File.join(File.expand_path("."), "global_settings.json")
        artifact_file = File.open(destination, 'wb') do |file|
          file.write(pretty_json)
        end
      end
    end

    def upload_global_settings
      global_settings_file = File.join(File.expand_path("."), "global_settings.json")
      nexus['service/local/global_settings/current'].put(File.read(global_settings_file), {:content_type => "application/json"}) do |response|
        case response.code
        when 400
          raise BadSettingsException.new(response.body)
        end
      end
    end

    def reset_global_settings
      default_json = nexus['service/local/global_settings/default'].get({:accept => "application/json"})
      nexus['service/local/global_settings/current'].put(default_json, {:content_type => "application/json"})
    end

    private
    def format_search_results(doc, group_id, artifact_id)
      versions = doc.xpath("//version").inject([]) {|array,node| array << "#{node.content()}"}
      indent_size = versions.max{|a,b| a.length <=> b.length}.size+4
      formated_results = ['Found Versions:']
      versions.inject(formated_results) do |array,version|
        temp_version = version + ":"
        array << "#{temp_version.ljust(indent_size)} `nexus-cli pull #{group_id}:#{artifact_id}:#{version}:tgz`"
      end
    end

    def parse_artifact_string(artifact)
      split_artifact = artifact.split(":")
      if(split_artifact.size < 4)
        raise ArtifactMalformedException
      end
      group_id, artifact_id, version, extension = split_artifact
      version.upcase! if version.casecmp("latest")
      return group_id, artifact_id, version, extension
    end
  end
end
