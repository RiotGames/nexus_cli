require 'nexus_cli'
require 'restclient'

describe NexusCli do
  it "gives you errors when configuration is missing a password" do
    expect {NexusCli::Remote.configuration = {url: "http://somewebsite.com", username: "admin"}}.to raise_error(NexusCli::InvalidSettingsException)
  end

  it "gives you errors when configuration is missing a username" do
    expect {NexusCli::Remote.configuration = {url: "http://somewebsite.com", password: "admin"}}.to raise_error(NexusCli::InvalidSettingsException)
  end

  it "gives you errors when you attempt to pull an artifact don't give a valid artifact name" do
    expect {NexusCli::Remote.pull_artifact "com.something:something:1.0.0", nil}.to raise_error(NexusCli::ArtifactMalformedException)
  end

  it "gives you errors when you attempt to push an artifact don't give a valid artifact name" do
    expect {NexusCli::Remote.push_artifact "com.something:something:1.0.0", nil}.to raise_error(NexusCli::ArtifactMalformedException)
  end

  it "gives you errors when you attempt to get an artifact's info and don't give a valid artifact name" do
    expect {NexusCli::Remote.get_artifact_info "com.something:something:1.0.0"}.to raise_error(NexusCli::ArtifactMalformedException)
  end
  
  it "gives you errors when you attempt to delete an artifact and don't give a valid artifact name" do
    expect {NexusCli::Remote.get_artifact_info "com.something:something:1.0.0"}.to raise_error(NexusCli::ArtifactMalformedException)
  end

  it "gives you errors when you attempt to pull an artifact and it cannot be found" do
    RestClient::Resource.any_instance.stub(:get).and_raise(RestClient::ResourceNotFound)
    expect {NexusCli::Remote.pull_artifact "com.something:something:1.0.0:tgz", nil}.to raise_error(NexusCli::ArtifactNotFoundException)
  end

  it "gives you errors when you attempt to get an artifact's info and it cannot be found" do
    RestClient::Resource.any_instance.stub(:get).and_raise(RestClient::ResourceNotFound)
    expect {NexusCli::Remote.get_artifact_info "com.something:something:1.0.0:tgz"}.to raise_error(NexusCli::ArtifactNotFoundException)
  end
end