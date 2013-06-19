require 'spec_helper'

describe String do
  describe "to_artifact_hash" do
    let(:to_artifact_hash) { string.to_artifact_hash }
    let(:string) { "com.test:mytest:1.0.0:tgz" }

    it "returns a hash" do
      expect(to_artifact_hash).to be_a(Hash)
    end

    context "when the split string is not long enough" do
      let(:string) { "com.test:mytest" }

      it "raises an exception" do
        expect{ to_artifact_hash }.to raise_error(NexusCli::ArtifactMalformedException)
      end
    end

    context "when the string can be converted" do
      it "returns the appropriate hash" do
        expect(to_artifact_hash).to eq({g: "com.test", a: "mytest", v: "1.0.0", e: "tgz"})
      end
    end

    context "when the extension is omitted" do
      let(:string) { "com.test:mytest:1.0.0" }

      it "defaults to jar" do
        expect(to_artifact_hash).to eq({g: "com.test", a: "mytest", v: "1.0.0", e: "jar"})
      end
    end

    context "when the version is sent as 'latest'" do
      let(:string) { "com.test:mytest:latest:tgz" }

      it "is capitalized" do
        expect(to_artifact_hash).to eq({g: "com.test", a: "mytest", v: "LATEST", e: "tgz"})
      end
    end
  end
end
