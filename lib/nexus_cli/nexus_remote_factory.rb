require 'httpclient'
require 'nokogiri'
require 'yaml'

module NexusCli
  class Factory
    class << self
      def create(overrides)
        @configuration = Configuration::parse(overrides)
        running_nexus_pro? ? ProRemote.new(overrides) : OSSRemote.new(overrides)
      end

      def configuration
        return @configuration if @configuration
      end

      def nexus
        client = HTTPClient.new
        # https://github.com/nahi/httpclient/issues/63
        client.set_auth(nil, configuration['username'], configuration['password'])
        client.www_auth.basic_auth.challenge(configuration['url'])
        return client
      end

      def nexus_url(url)
        File.join(configuration['url'], url)
      end

      def status
        response = nexus.get(nexus_url("service/local/status"))
        case response.status
        when 200
          doc = Nokogiri::XML(response.content).xpath("/status/data")
          data = Hash.new
          data['app_name'] = doc.xpath("appName")[0].text
          data['version'] = doc.xpath("version")[0].text
          data['edition_long'] = doc.xpath("editionLong")[0].text
          data['state'] = doc.xpath("state")[0].text
          data['started_at'] = doc.xpath("startedAt")[0].text
          data['base_url'] = doc.xpath("baseUrl")[0].text
          return data
        when 401
          raise PermissionsException
        when 503
          raise CouldNotConnectToNexusException
        else
          raise UnexpectedStatusCodeException.new(response.status)
        end
      end

      private

      def running_nexus_pro?
        return status['edition_long'] == "Professional" ? true : false
      end
    end
  end
end
