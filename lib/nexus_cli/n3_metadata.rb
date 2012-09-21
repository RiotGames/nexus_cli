require 'nokogiri'
require 'base64'

module NexusCli
  module N3Metadata
    class << self
      # Checks if the custom metadata key is valid.
      # Valid characters are alphanumeric with no special characeters.
      def valid_n3_key?(element)
        return !element.nil? && !element.match(/^[a-zA-Z0-9]+$/).nil? ? true : false
      end

      # Checks if the custom metadata value is valid.
      # Valid characters are anything but quotes.
      def valid_n3_value?(element)
        return !element.nil? && !element.match(/^[^"'\\]*$/).nil? ? true : false
      end

      # Check if the custom metadata search type is valid.
      def valid_n3_search_type?(element)
        return !element.nil? && ["equal", "notequal", "matches", "bounded"].include?(element)
      end

      # Creates a custom metadata subject for HTTP requests.
      def create_base64_subject(group_id, artifact_id, version, extension)
        return Base64.urlsafe_encode64("urn:maven/artifact##{group_id}:#{artifact_id}:#{version}::#{extension}")
      end

      # Parses the regular custom metadata xml into a simpler format containing only the custom metadata.
      def convert_result_to_simple_xml(custom_metadata)
        request = []
        Nokogiri::XML(custom_metadata).root.search("//customMetadataResponse/data/customMetadata[namespace=\"urn:nexus/user#\"]").each do |row|
          request.push(create_tag(row.at("key").text.strip, row.at("value").text.strip))
        end
        return Nokogiri::XML("<artifact-resolution><data>#{request.join}</data></artifact-resolution>").root.to_xml(:indent => 4)
      end

      # Parses the regular custom metadata xml into a hash containing only the custom metadata.
      def convert_result_to_hash(custom_metadata)
        request = {}
        Nokogiri::XML(custom_metadata).root.search("//customMetadataResponse/data/customMetadata[namespace=\"urn:nexus/user#\"]").each do |row|
          request[row.at("key").text.strip] = row.at("value").text.strip
        end
        return request
      end

      # Create the request from the specified list of custom metadata key:value pairs
      # @info If the target hash contains empty values for a key that exist in source, the metadata will be deleted
      # @param [Hash] source The source hash of custom metadata key:value pairs
      # @param [Hash] target The target hash to merge with the source hash (optional)
      # @result [Hash] The resulting merge of the source and target hashes
      def create_metadata_hash(source, target={})
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
