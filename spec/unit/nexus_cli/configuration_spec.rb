require 'spec_helper'

describe NexusCli::Configuration do
  subject { configuration }
  let(:configuration) { described_class }
  let(:config_instance) { configuration.from_overrides(valid_config) }
  let(:url) { "http://some-url.com" }
  let(:repository) { "releases" }
  let(:username) { "kallan" }
  let(:password) { "password" }

  let(:valid_config) do
    {
      "url" => "http://somewebsite.com",
      "repository" => "foo",
      "username" => "admin",
      "password" => "password"
    }
  end

  describe "::from_overrides" do
    subject { from_overrides }
    let(:from_overrides) { configuration.from_overrides(valid_config) }

    it "returns a new Configuration object" do
      expect(from_overrides).to be_a(NexusCli::Configuration)
    end
  end

  describe "::from_file" do
    subject { from_file }
    let(:from_file) { configuration.from_file }

    before do
      YAML.stub(:load_file).and_return(valid_config)
    end

    context "when the NEXUS_CONFIG environment variable exists" do
      let(:nexus_config_path) { "/home/var/nexus_cli" }

      before do
        ENV['NEXUS_CONFIG'] = nexus_config_path
      end

      it "loads the config file from NEXUS_CONFIG" do
        YAML.should_receive(:load_file).with(nexus_config_path)
        from_file
      end
    end

    context "when the NEXUS_CONFIG environment variable does not exist" do
      let(:nexus_config_path) { File.expand_path(NexusCli::Configuration::DEFAULT_FILE) }

      before do
        ENV['NEXUS_CONFIG'] = nil
      end

      it "loads the config file from DEFAULT_FILE" do
        YAML.should_receive(:load_file).with(nexus_config_path)
        from_file
      end
    end

    it "returns a new Configuration object" do
      expect(from_file).to be_a(NexusCli::Configuration)
    end
  end

  describe "::validate!" do
    subject { validate! }
    let(:validate!) {described_class.validate!(invalid_config)}
    let(:invalid_config) do
      described_class.new(url: nil, repository: "something", username: "someone", password: "somepass")
    end

    context "when the object is invalide" do
      it "raises an error" do
        expect { validate! }.to raise_error(NexusCli::InvalidSettingsException)
      end
    end
  end

  describe "#new" do
    subject { new_config }
    let(:new_config) { described_class.new(url: url, repository: repository, username: username, password: password) }

    it "creates a new Configuration object" do
      expect(new_config).to be_a(NexusCli::Configuration)
    end
  end

  describe "#url" do  
    it "returns the url" do
      expect(config_instance.url).to eq("http://somewebsite.com")
    end
  end

  describe "#repository" do
    let(:repository_config) { described_class.new(url: url, repository: repository, username: username, password: password) }

    it "returns the repository" do
      expect(config_instance.repository).to eq("foo")
    end

    context "when repository has illegal values" do
      let(:repository) { "ILLEGAL VALUE" }
      it "makes it legal" do
        expect(repository_config.repository).to eq("illegal_value")
      end
    end
  end

  describe "#username" do
    it "returns the username" do
      expect(config_instance.username).to eq("admin")
    end
  end

  describe "#password" do
    it "returns the password" do
      expect(config_instance.password).to eq("password")
    end
  end
end
