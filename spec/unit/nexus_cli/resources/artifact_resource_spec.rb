require 'spec_helper'

describe NexusCli::ArtifactResource do
  let(:artifact_resource) { described_class.new(connection_registry) }
  let(:connection_registry) { double(:[] => connection) }
  let(:connection) { double(:get => response, :put => response, :delete => response, :stream => nil, :default_repository => "releases") }
  let(:response) { double(:body => double(:data => nil), :headers => {}) }
  let(:artifact_id) { "com.test:my-test:1.0.0:tgz" }
  let(:artifact_id_hash) do
    {
      g: "com.test",
      a: "my-test",
      v: "1.0.0",
      e: "tgz",
      r: "releases"
    }
  end

  before do
    NexusCli::ArtifactObject.stub(:from_nexus_response)
  end

  describe "#find" do
    let(:find) { artifact_resource.find(artifact_id) }

    it "attempts to find an artifact" do
      artifact_id_hash = { g: "com.test", a: "my-test", v: "1.0.0", e: "tgz", r: "releases"}
      connection.should_receive(:get).with("service/local/artifact/maven/resolve", artifact_id_hash)
      find
    end
  end

  describe "#download" do
    let(:download) { artifact_resource.download(artifact_id) }
    let(:response) { double(:body => {}, :headers => {"location" => redirect_url}) }
    let(:redirect_url) { "http://some-redirect.com" }
    let(:current_dir) { File.expand_path(".") }

    it "attempts to download the artifact" do
      connection.should_receive(:stream).with(redirect_url, File.join(current_dir, "my-test-1.0.0.tgz"))
      download
    end

    context "when an alternate location is provided" do
      let(:download) { artifact_resource.download(artifact_id, location) }
      let(:location) { "/artifacts" }

      it "attempts to download the artifact to the provided location" do
        connection.should_receive(:stream).with(redirect_url, File.join(location, "my-test-1.0.0.tgz"))
        download
      end
    end

    context "when asked to download the latest version of an artifact" do
      let(:artifact_id) { "com.test:my-test:latest:tgz" }

      before do
        artifact_resource.stub(:find).and_return(double(:version => "2.0.1"))
      end

      it "loads the artifact to get its true version" do
        connection.should_receive(:stream).with(redirect_url, File.join(current_dir, "my-test-2.0.1.tgz"))
        download
      end
    end
  end

  describe "#upload" do
    let(:upload) { artifact_resource.upload(artifact_id, file) }
    let(:file) { "my-artifact.tgz" }

    before do
      File.stub(:read)
      Tempfile.stub(:open)
    end

    context "when the upload is a success" do
      before do
        connection.stub(:put).and_return(double(:success? => true))
      end

      it "uploads an artifact, gives the artifact a pom and regenerates metadata" do
        connection.should_receive(:put).twice
        connection.should_receive(:delete).with("service/local/metadata/repositories/releases/content/com/test/my-test/1.0.0")

        upload
      end
    end

    context "when the upload is a failure" do
      before do
        connection.stub(:put).and_return(double(:success? => false))
      end

      it "raises an error" do
        expect{upload}.to raise_error(NexusCli::Errors::BadUploadRequestException)
      end
    end
  end

  describe "#delete" do
    let(:delete) { artifact_resource.delete(artifact_id) }

    it "deletes the artifact" do
      connection.should_receive(:delete).with("content/repositories/releases/com/test/my-test/1.0.0")
      delete
    end
  end

  describe "#delete_metadata" do
    let(:delete_metadata) { artifact_resource.delete_metadata(artifact_id) }

    it "deletes an artifacts metadata" do
      connection.should_receive(:delete).with("service/local/metadata/repositories/releases/content/com/test/my-test/1.0.0")
      delete_metadata
    end
  end

  describe "#latest?" do
    let(:latest?) { artifact_resource.latest?(version) }

    context "when the version is 'latest'" do
      let(:version) { "latest" }
      it "returns true" do
        expect(latest?).to be_true
      end
    end

    context "when the version is not 'latest'" do
      let(:version) { "foo" }

      it "returns false" do
        expect(latest?).to be_false
      end
    end
  end
end
