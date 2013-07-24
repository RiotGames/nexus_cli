module NexusCli
  class Artifact
    attr_reader :group_id
    attr_reader :artifact_id
    attr_reader :extension
    attr_reader :classifier
    attr_reader :version
    attr_reader :file_name

    # Constructs an artifact object from Maven co-ordinates
    # See http://maven.apache.org/pom.html#Maven_coordinatess
    # for more information on maven coordinatess
    # 
    # @param  coordinates [String] the Maven identifier
    # 
    # @return [Array<String>] an Array with four elements
    def initialize(coordinates)
      @group_id, @artifact_id, @extension, @classifier, @version = parse_coordinates(coordinates)

      if @classifier.nil?
        @file_name = "#{@artifact_id}-#{@version}.#{@extension}"
      else
        @file_name = "#{@artifact_id}-#{@version}-#{@classifier}.#{@extension}"
      end
    end

    private

    def parse_coordinates(coordinates)
      split_coordinates = coordinates.split(":")
      if(split_coordinates.size < 3 or split_coordinates.size > 5)
        raise ArtifactMalformedException
      end

      group_id = split_coordinates[0]
      artifact_id = split_coordinates[1]
      extension = split_coordinates.size > 3 ? split_coordinates[2] : "jar"
      classifier = split_coordinates.size > 4 ? split_coordinates[3] : nil
      version = split_coordinates[-1]

      version.upcase! if version == "latest"

      return group_id, artifact_id, extension, classifier, version
    end
  end
end
