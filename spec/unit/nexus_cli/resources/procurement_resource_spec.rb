require 'spec_helper'

describe NexusCli::ProcurementResource do
  let(:procurement_resource) { described_class.new(connection_registry) }
  let(:connection_registry) { double(:[] => connection) }
  let(:connection) { double(:get => response, :delete => response, :post => response) }
  let(:response) { double(:body => Hashie::Mash.new(:data => []), :headers => {}) }
  let(:repository) { "artifacts" }
  let(:procured_from_repository) { "procured" }

  describe "#start" do
    let(:start) { procurement_resource.start(repository, procured_from_repository) }

    it "starts procurement for the given repository" do
      connection.should_receive(:post).with(/procurement\/manage/, kind_of(String))
      start
    end
  end

  describe "#stop" do
    let(:stop) { procurement_resource.stop(repository) }

    it "stops procurement for the given repository" do
      connection.should_receive(:delete).with(/procurement\/manage\/artifacts/)
      stop
    end
  end

  describe "#add_rule" do
    let(:add_rule) { procurement_resource.add_rule(repository, rule) }
    let(:rule) { NexusCli::RuleObject.new({}) }

    it "adds the rule to the procurement repository" do
      connection.should_receive(:post).with(/procurement\/resolutions\/artifacts/, kind_of(NexusCli::RuleObject))
      add_rule
    end
  end

  describe "#rules" do
    let(:rules) { procurement_resource.rules(repository) }

    it "returns an array of procurement rules" do
      connection.should_receive(:get).with(/procurement\/resolutions\/artifacts/)
      expect(rules).to be_a(Array)
    end
  end
end
