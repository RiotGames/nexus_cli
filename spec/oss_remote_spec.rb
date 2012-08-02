require 'nexus_cli'

remote = NexusCli::OSSRemote.new(nil)

describe NexusCli do
  it "gives you errors when you attempt to pull an artifact don't give a valid artifact name" do
    expect {remote.pull_artifact "com.something:something:1.0.0", nil}.to raise_error(NexusCli::ArtifactMalformedException)
  end

  it "gives you errors when you attempt to get an artifact's info and don't give a valid artifact name" do
    expect {remote.get_artifact_info "com.something:something:1.0.0"}.to raise_error(NexusCli::ArtifactMalformedException)
  end
  
  it "gives you errors when you attempt to pull an artifact and it cannot be found" do
    RestClient::Resource.any_instance.stub(:get).and_raise(RestClient::ResourceNotFound)
    expect {remote.pull_artifact "com.something:something:1.0.0:tgz", nil}.to raise_error(NexusCli::ArtifactNotFoundException)
  end

  it "gives you errors when you attempt to get an artifact's info and it cannot be found" do
    RestClient::Resource.any_instance.stub(:get).and_raise(RestClient::ResourceNotFound)
    expect {remote.get_artifact_info "com.something:something:1.0.0:tgz"}.to raise_error(NexusCli::ArtifactNotFoundException)
  end
end