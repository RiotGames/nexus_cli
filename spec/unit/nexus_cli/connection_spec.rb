require 'spec_helper'

describe NexusCli::Connection do
  let(:server_url) { "https://repository.apache.org" }
  let(:configuration) { NexusCli::Configuration.new(config_options) }
  let(:config_options) do
    {
      "url" => "http://somewebsite.com",
      "repository" => "foo",
      "username" => "admin",
      "password" => "password"
    }
  end

  describe "#new" do
    let(:connection) { described_class.new(server_url, configuration) }
    
    it "sets an accept header of application/json" do
      expect(connection.headers).to include("Accept" => "application/json")
    end

    it "sets a content-type header of application/json" do
      expect(connection.headers).to include("Content-Type" => "application/json")
    end

    it "sets a user-agent header of NexusCli" do
      expect(connection.headers).to include("User-Agent")
    end

    it "sets ssl_verify" do
      expect(connection.ssl).to include(:verify)
    end
  end 
end
