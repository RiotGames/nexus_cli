require 'restclient'
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
        RestClient::Resource.new configuration["url"], :user => configuration["username"], :password => configuration["password"]
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

      private
      def running_nexus_pro?
        return status['edition_long'] == "Professional" ? true : false
      end
    end
  end
end
