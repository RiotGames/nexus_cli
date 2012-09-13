require 'nokogiri'

module NexusCli
  module N3Metadata
    class << self
      def valid_n3_key?(element)
        return !element.match(/^[a-zA-Z0-9]+$/).nil? ? true : false
      end

      def valid_n3_value?(element)
        return !element.match(/^[^"'\\]*$/).nil? ? true : false
      end

      def valid_n3_search_type?(element)
        return ["equal", "notequal", "matches", "bounded"].include?(element)
      end

      def create_custom_metadata_subject(group_id, artifact_id, version, extension)
        return "urn:maven/artifact##{group_id}:#{artifact_id}:#{version}::#{extension}"
      end

      def parse_request_into_simple(custom_metadata)
        request = []
        Nokogiri::XML(custom_metadata).root.search("//customMetadataResponse/data/customMetadata[namespace=\"urn:nexus/user#\"]").each do |row|
          request.push(create_tag(row.at("key").text.strip, row.at("value").text.strip))
        end
        return Nokogiri::XML("<artifact-resolution><data>#{request.join}</data></artifact-resolution>").root.to_xml(:indent => 4)
      end

      def parse_request_into_hash(custom_metadata)
        request = {}
        Nokogiri::XML(custom_metadata).root.search("//customMetadataResponse/data/customMetadata[namespace=\"urn:nexus/user#\"]").each do |row|
          request[row.at("key").text.strip] = row.at("value").text.strip
        end
        return request
      end

      def generate_request_from_hash(source, target={})
        request = []
        source.merge(target).each do |key, value|
          request.push({:namespace => "urn:nexus/user#", :key => key, :value => value, :readOnly => false}) unless value.empty?
        end
        return request
      end

      def missing_custom_metadata?(custom_metadata)
        return !custom_metadata.match(/<data[ ]*\/>/).nil? ? true : false
      end

      private

      def create_tag(tag, value)
        return "<#{tag}>#{value}</#{tag}>"
      end
    end
  end
end
