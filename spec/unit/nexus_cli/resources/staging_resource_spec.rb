require 'spec_helper'

describe NexusCli::StagingResource do
  let(:staging_resource) { described_class.new(connection_registry) }
  let(:connection_registry) { double(:[] => connection) }
  let(:connection) { double(:get => response, :put => response, :post => response) }
  let(:response) { double(:body => Hashie::Mash.new(:data => []), :headers => {}) }
  let(:repository_id) { "123" }

  describe "#upload" do
    let(:upload) { staging_resource.upload(artifact_id, file) }
    let(:artifact_id) { "com.mytest:test:1.0.0:tgz" }
    let(:file) { double }

    before do
      File.stub(:read).and_return("contents")
    end

    it "uploads to the default path" do
      connection.should_receive(:put).with(/staging\/deploy\/maven2/, "contents")
      upload
    end

    context "when a repository_id is given" do
      let(:upload) { staging_resource.upload(artifact_id, repository_id, file) }

      it "uploads to the specified repository" do
        connection.should_receive(:put).with(/staging\/deployByRepositoryId\/123/, "contents")
        upload
      end
    end
  end

  describe "#close" do
    let(:close) { staging_resource.close(repository_id) }

    it "closes the staging repository" do
      connection.should_receive(:post).with(/staging\/bulk\/close/, kind_of(String))
      close
    end
  end

  describe "#drop" do
    let(:drop) { staging_resource.drop(repository_id) }

    it "drops the staging repository" do
      connection.should_receive(:post).with(/staging\/bulk\/drop/, kind_of(String))
      drop
    end
  end

  describe "#promote" do
    let(:promote) { staging_resource.promote(repository_id, promotion_id) }
    let(:promotion_id) { "1234" }

    it "promotes the staging repository" do
      connection.should_receive(:post).with(/staging\/bulk\/promote/, kind_of(String))
      promote
    end
  end

  describe "#profiles" do
    let(:profiles) { staging_resource.profiles }

    it "returns an array of staging profiles" do
      connection.should_receive(:get).with(/staging\/profiles/)
      expect(profiles).to be_a(Array)
    end
  end

  describe "#create_profile" do
    let(:create_profile) { staging_resource.create_profile(profile) }
    let(:profile) { NexusCli::StagingProfileObject.new({}) }

    it "creates a new profile" do
      connection.should_receive(:post).with(/staging\/profiles/, kind_of(NexusCli::StagingProfileObject))
      create_profile
    end
  end
end
