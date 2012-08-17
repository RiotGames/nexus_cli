require 'spec_helper'

remote = NexusCli::OSSRemote.new({'url' => 'http://localhost:8081/nexus', 'repository' => 'releases', 'username' => 'admin', 'password' => 'admin123'})

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

  it "gives you an error when you try to update a user that doesnt exist" do
    stub_request(:get, "http://admin:admin123@localhost:8081/nexus/service/local/users/qwertyasdf").
         with(:headers => {'Accept'=>'application/json', 'Accept-Encoding'=>'gzip, deflate', 'User-Agent'=>'Ruby'}).
         to_return(:status => 404, :body => "", :headers => {})
    expect {remote.update_user(:userId => "qwertyasdf")}.to raise_error(NexusCli::UserNotFoundException)
  end
end