module NexusCli
  class Client
    class ConnectionSupervisor < Celluloid::SupervisionGroup
      def initialize(registry, configuration)
        super(registry)
        pool(NexusCli::Connection, size: 10, args: [
          configuration
        ], as: :connection_pool)
      end
    end

    class ResourceSupervisor < Celluloid::SupervisionGroup
      def initialize(registry, connection_registry)
        super(registry)
        supervise_as :artifact_resource, NexusCli::ArtifactResource, connection_registry
        supervise_as :staging_resource, NexusCli::StagingResource, connection_registry
        supervise_as :procurement_resource, NexusCli::ProcurementResource, connection_registry
      end
    end

    include Celluloid

    def initialize(overrides=nil)
      @configuration = overrides ? Configuration.from_overrides(overrides) : Configuration.from_file
      Configuration.validate!(@configuration)

      @connection_registry   = Celluloid::Registry.new
      @resource_registry    = Celluloid::Registry.new
      @connection_supervisor = ConnectionSupervisor.new(@connection_registry, @configuration)
      @resource_supervisor  = ResourceSupervisor.new(@resource_registry, @connection_registry)
    rescue InvalidSettingsException => ex
      abort(ex.message)
    end

    # @return [NexusCli::ArtifactResource]
    def artifact
      @resource_registry[:artifact_resource]
    end

    def staging
      @resource_registry[:staging_resource]
    end

    def procurement
      @resource_registry[:procurement_resource]
    end
  end
end
