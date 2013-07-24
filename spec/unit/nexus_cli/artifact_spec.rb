require 'spec_helper'

describe NexusCli::Artifact do

  describe "#new" do
    it "gives you errors when you under specify" do
      expect { described_class.new("group:artifact") }.to raise_error(NexusCli::ArtifactMalformedException)
    end

    it "gives you errors when you over specify" do
      expect { described_class.new("group:artifact:extension:classifier:version:garbage") }.to raise_error(NexusCli::ArtifactMalformedException)
    end

    context "when extension and classifier are omitted" do
      subject { new_artifact }
      let(:new_artifact) { described_class.new("group:artifact:version") }

      it "creates a new Artifact object" do
        expect(new_artifact).to be_a(NexusCli::Artifact)
      end

      it "has the correct attributes" do
        expect(new_artifact.group_id).to eq("group")
        expect(new_artifact.artifact_id).to eq("artifact")
        expect(new_artifact.extension).to eq("jar")
        expect(new_artifact.classifier).to be_nil
        expect(new_artifact.version).to eq("version")
        expect(new_artifact.file_name).to eq("artifact-version.jar")
      end
    end

    context "when just extension is specified" do
      subject { new_artifact }
      let(:new_artifact) { described_class.new("group:artifact:extension:version") }

      it "creates a new Artifact object" do
        expect(new_artifact).to be_a(NexusCli::Artifact)
      end

      it "has the correct attributes" do
        expect(new_artifact.group_id).to eq("group")
        expect(new_artifact.artifact_id).to eq("artifact")
        expect(new_artifact.extension).to eq("extension")
        expect(new_artifact.classifier).to be_nil
        expect(new_artifact.version).to eq("version")
        expect(new_artifact.file_name).to eq("artifact-version.extension")
      end
    end

    context "when both extension and classifer are specified" do
      subject { new_artifact }
      let(:new_artifact) { described_class.new("group:artifact:extension:classifier:version") }

      it "creates a new Artifact object" do
        expect(new_artifact).to be_a(NexusCli::Artifact)
      end

      it "has the correct attributes" do
        expect(new_artifact.group_id).to eq("group")
        expect(new_artifact.artifact_id).to eq("artifact")
        expect(new_artifact.extension).to eq("extension")
        expect(new_artifact.classifier).to eq("classifier")
        expect(new_artifact.version).to eq("version")
        expect(new_artifact.file_name).to eq("artifact-version-classifier.extension")
      end
    end

    context "when you specify latest as the version" do
      subject { new_artifact }
      let(:new_artifact) { described_class.new("group:artifact:latest") }

      it "upper cases version" do
        expect(new_artifact.group_id).to eq("group")
        expect(new_artifact.artifact_id).to eq("artifact")
        expect(new_artifact.extension).to eq("jar")
        expect(new_artifact.classifier).to be_nil
        expect(new_artifact.version).to eq("LATEST")
        expect(new_artifact.file_name).to eq("artifact-LATEST.jar")
      end
    end
  end
end
