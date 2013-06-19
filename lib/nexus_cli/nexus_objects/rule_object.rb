module NexusCli
  class RuleObject < NexusObject

    attribute :id,
      type: String

    attribute 'artifact_coordinate.group_id',
      type: String,
      default: ""
    def_delegator :artifact_coordinate, :group_id, :group_id

    attribute 'artifact_coordinate.artifact_id',
      type: String,
      default: ""
    def_delegator :artifact_coordinate, :artifact_id, :artifact_id

    attribute 'artifact_coordinate.version',
      type: String,
      default: ""
    def_delegator :artifact_coordinate, :version, :version

    attribute :rule_type_id,
      type: Symbol,
      default: ""

    attribute :properties,
      type: Array,
      default: []
  end
end
