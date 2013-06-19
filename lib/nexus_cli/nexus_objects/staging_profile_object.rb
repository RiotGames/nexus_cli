module NexusCli
  class StagingProfileObject < NexusObject

    attribute :resource_uri,
      type: String

    attribute :id,
      type: String

    attribute :in_progress,
      type: [ TrueClass, FalseClass ]

    attribute :order,
      type: Fixnum

    attribute :deploy_uri,
      type: String

    attribute :name,
      type: String,
      default: ""

    attribute :repository_template_id,
      type: String,
      default: ""

    attribute :repository_type,
      type: String,
      default: "maven2"

    attribute :repository_target_id,
      type: String,
      default: ""

    attribute :target_groups,
      type: Array,
      default: []

    attribute :finish_notify_roles,
      type: Array,
      default: []

    attribute :promotion_notify_roles,
      type: Array,
      default: []

    attribute :drop_notify_roles,
      type: Array,
      default: []

    attribute :close_rule_sets,
      type: Array,
      default: []

    attribute :promote_rule_sets,
      type: Array,
      default: []

    attribute :promotion_target_repository,
      type: String,
      default: ""

    attribute :drop_notify_creator,
      type: [ TrueClass, FalseClass ],
      default: true

    attribute :finish_notify_creator,
      type: [ TrueClass, FalseClass ],
      default: true

    attribute :promotion_notify_creator,
      type: [ TrueClass, FalseClass ],
      default: true

    attribute :auto_staging_disabled,
      type: [ TrueClass, FalseClass ],
      default: false

    attribute :repositories_searchable,
      type: [ TrueClass, FalseClass ],
      default: true

    attribute :mode,
      type: String,
      default: "BOTH"
  end
end
