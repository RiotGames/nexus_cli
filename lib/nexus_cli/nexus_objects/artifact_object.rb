module NexusCli
  class ArtifactObject < NexusObject
    class << self
      def from_nexus_response(response)
        attributes = Hash.new

        attributes[:group_id] = response.groupId
        attributes[:artifact_id] = response.artifactId
        attributes[:version] = response.version
        attributes[:extension] = response.extension
        attributes[:present_locally] = response.presentLocally
        attributes[:snapshot] = response.snapshot
        attributes[:snapshot_build_number] = response.snapshotBuildNumber
        attributes[:snapshot_time_stamp] = response.snapshotTimeStamp
        attributes[:sha1] = response.sha1
        attributes[:repository_path] = response.repositoryPath
        attributes[:repository] = response.repository
        new(attributes)
      end
    end

    attribute :present_locally,
      type: [ TrueClass, FalseClass ]

    attribute :group_id,
      type: String,
      required: true

    attribute :artifact_id,
      type: String,
      required: true

    attribute :version,
      type: String,
      required: true

    attribute :extension,
      type: String,
      default: "jar"

    attribute :snapshot,
      type: [ TrueClass, FalseClass ]

    attribute :snapshot_build_number,
      type: Fixnum

    attribute :snapshot_time_stamp,
      type: Fixnum

    attribute :sha1,
      type: String

    attribute :repository,
      type: String

    attribute :repository_path,
      type: String

    def initialize(attributes)
      mass_assign(attributes)
    end

    # Translates the object into a valid artifact identifier that
    # can be used in other Nexus requests
    # 
    # @example artifact.to_s => "com.test:my-artifact:1.0.0:tgz" 
    #
    # @return [String]
    def to_s
      "#{self.group_id}:#{self.artifact_id}:#{self.version}:#{self.extension}"
    end
  end
end
