require 'spec_helper'

describe NexusCli::RemoteFactory do
  subject { remote_factory }
  let(:remote_factory) { described_class }

  describe "::create" do
    subject { create }
    let(:create) { remote_factory.create(overrides) }

    before do
      NexusCli::Connection.stub(:new)
      remote_factory.stub(:running_nexus_pro?).and_return(false)
      NexusCli::OSSRemote.stub(:new)
    end

    context "when overrides are passed in" do
      let(:overrides) {
        {
          "url" => "http://somewebsite.com",
          "repository" => "foo",
          "username" => "admin",
          "password" => "password"
        }
      }

      it "loads configuration from the overrides" do
        NexusCli::Configuration.should_receive(:from_overrides).with(overrides)
        create
      end
    end

    context "when no overrides are passed in" do
      let(:overrides) { nil }

      it "loads configuration from the config file" do
        NexusCli::Configuration.should_receive(:from_file)
        create
      end
    end
  end
end
