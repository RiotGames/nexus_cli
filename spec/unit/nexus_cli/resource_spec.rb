require 'spec_helper'

describe NexusCli::Resource do
  let(:resource) { described_class.new(connection_registry) }
  let(:connection_registry) { double }
  let(:artifact_id) { "com.test:my-test:1.0.0:tgz" }

  describe "#repository_path_for" do
    let(:repository_path_for) { resource.repository_path_for(artifact_id) }

    it "returns the repository path" do
      expect(repository_path_for).to eq("com/test/my-test/1.0.0")
    end
  end

  describe "#file_name_for" do
    let(:file_name_for) { resource.file_name_for(artifact_id) }

    it "returns a composition of the resulting file name" do
      expect(file_name_for).to eq("my-test-1.0.0.tgz")
    end
  end
end