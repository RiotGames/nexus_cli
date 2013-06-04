require 'spec_helper'

describe NexusCli::CustomMetadataActions do
  let(:custom_metadata_actions) { injected_module.new }
  let(:injected_module) do
    Class.new {
      include NexusCli::CustomMetadataActions
    }
  end
  let(:document) { REXML::Document.new(File.read(fixtures_path.join('metadata_search.xml'))) }

  describe "::get_artifact_array" do
    subject { get_artifact_array }
    let(:get_artifact_array) { custom_metadata_actions.send(:get_artifact_array, document) }

    it "returns an array of strings" do
      get_artifact_array.should be_a(Array)
      get_artifact_array.each { |element| element.should be_a(String) }
    end
  end  
end
