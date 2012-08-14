require 'nexus_cli'

remote = NexusCli::ProRemote.new(nil)

describe NexusCli do
  it "gives you errors when you attempt to get an artifact's custom info and don't give a valid artifact name" do
    expect {remote.get_artifact_custom_info("com.something:something:1.0.0")}.to raise_error(NexusCli::ArtifactMalformedException)
  end

  it "gives you errors when you attempt to get an artifact's custom info and it cannot be found" do
    RestClient::Resource.any_instance.stub(:get).and_raise(RestClient::ResourceNotFound)
    expect {remote.get_artifact_custom_info("com.something:something:1.0.0:tgz")}.to raise_error(NexusCli::ArtifactNotFoundException)
  end

  it "gives you errors when you attempt to update an artifact's custom info and don't give valid parameters" do
    expect {remote.update_artifact_custom_info("com.something:something:1.0.0:tgz", "_somebadkey:_somebadvalue")}.to raise_error(NexusCli::N3ParameterMalformedException)
  end

  it "gives you errors when you attempt to update an artifact's custom info and don't give valid parameters" do
    expect {remote.update_artifact_custom_info("com.something:something:1.0.0:tgz", "_somebadkey")}.to raise_error(NexusCli::N3ParameterMalformedException)
  end

  it "gives you errors when you attempt to clear an artifact's custom info and it cannot be found" do
    RestClient::Resource.any_instance.stub(:get).and_raise(RestClient::ResourceNotFound)
    expect {remote.clear_artifact_custom_info("com.something:something:1.0.0:tgz")}.to raise_error(NexusCli::ArtifactNotFoundException)
  end

  it "gives you errors when you attempt to search for artifacts using custom info and don't give valid key" do
    expect {remote.search_artifacts("somekey_:equal:somevalue")}.to raise_error(NexusCli::SearchParameterMalformedException)
  end

  it "gives you errors when you attempt to search for artifacts using custom info and don't give valid value" do
    expect {remote.search_artifacts("somekey:equal:somevalue \"\'\\/")}.to raise_error(NexusCli::SearchParameterMalformedException)
  end

  it "gives you errors when you attempt to search for artifacts using custom info and don't give valid search type" do
    expect {remote.search_artifacts("somekey:equals:somevalue")}.to raise_error(NexusCli::SearchParameterMalformedException)
  end

  it "gives you errors when you attempt to search for artifacts using custom info and don't give valid parameters" do
    expect {remote.search_artifacts("somekey")}.to raise_error(NexusCli::SearchParameterMalformedException)
  end
end
