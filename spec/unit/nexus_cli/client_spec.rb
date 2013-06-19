require 'spec_helper'

describe NexusCli::Client do
  let(:client) { described_class.new(configuration) }
  let(:configuration) do
    {
      "server_url" => "http://somewebsite.com",
      "repository" => "foo",
      "username" => "admin",
      "password" => "password"
    }
  end

  describe "#new" do
    it "makes a new one" do
      expect(client).to be_a(NexusCli::Client)
    end
  end

  describe "#artifact" do
    let(:artifact) { client.artifact }

    it "returns the artifact resource" do
      expect(artifact).to be_a(NexusCli::ArtifactResource)
    end
  end
end
