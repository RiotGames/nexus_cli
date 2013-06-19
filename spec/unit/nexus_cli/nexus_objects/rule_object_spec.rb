require 'spec_helper'

describe NexusCli::RuleObject do
  describe ":from_nexus_response" do
    let(:response) do
      Hashie::Mash.new(:artifactCoordinate => Hashie::Mash.new,
        :ruleTypeId => "simple", :properties => [Hashie::Mash.new])
    end

    it "returns a new instance of the class" do
      expect(described_class.from_nexus_response(response)).to be_a(NexusCli::RuleObject)
    end
  end
end
