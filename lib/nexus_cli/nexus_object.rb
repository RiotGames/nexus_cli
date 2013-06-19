module NexusCli
  class NexusObject < Buff::Config::JSON
    class << self
      def from_nexus_response(response)
        new(response.deep_transform_keys { |key| key.underscore } )
      end
    end

    extend Forwardable

    def initialize(attributes)
      mass_assign(attributes)
    end

    def to_json(options = {})
      attributes = self._attributes_.to_hash
      attributes.reject! { |key, value| value.nil? }

      enveloped = Hash[{"data" => attributes}]
      JSON.dump(enveloped.deep_transform_keys { |key| key.camelize(:lower) })
    end
  end
end
