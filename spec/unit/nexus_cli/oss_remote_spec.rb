require 'spec_helper'

remote = NexusCli::OSSRemote.new(
  'url' => 'http://localhost:8081/nexus',
  'repository' => 'releases',
  'username' => 'admin',
  'password' => 'admin123'
)


fake_xml = <<EOS
    <search-results>
  <totalCount>1</totalCount>
  <from>-1</from>
  <count>-1</count>
  <tooManyResults>false</tooManyResults>
  <data>
    <artifact>
      <resourceURI>https://someuri.com/com/something/thing.tgz</resourceURI>
      <groupId>com.something</groupId>
      <artifactId>thing-stuff</artifactId>
      <version>0.4.0</version>
      <packaging>tgz</packaging>
      <extension>tgz</extension>
      <repoId>company_artifact</repoId>
      <contextId>Company Replicated Artifacts</contextId>
      <pomLink>https://somedomain.com/nexus/service/local/artifact/maven/redirect?r=company_artifact&amp;g=com.something&amp;a=thing-stuff&amp;v=0.4.0&amp;e=pom</pomLink>
      <artifactLink>https://somedomain/nexus/service/local/artifact/maven/redirect?r=ompany_artifact&amp;g=com.something&amp;a=thing-stuff&amp;v=0.4.0&amp;e=tgz</artifactLink>
    </artifact>
  </data>
</search-results>
EOS

describe NexusCli do
  it "gives you errors when you attempt to pull an artifact don't give a valid artifact name" do
    expect {remote.pull_artifact "com.something:something", nil}.to raise_error(NexusCli::ArtifactMalformedException)
  end

  it "gives you errors when you attempt to get an artifact's info and don't give a valid artifact name" do
    expect {remote.get_artifact_info "com.something:something"}.to raise_error(NexusCli::ArtifactMalformedException)
  end

  it "gives you errors when you attempt to pull an artifact and it cannot be found" do
    HTTPClient.any_instance.stub(:get).and_raise(NexusCli::ArtifactNotFoundException)
    expect {remote.pull_artifact "com.something:something:tgz:1.0.0", nil}.to raise_error(NexusCli::ArtifactNotFoundException)
  end

  it "gives you errors when you attempt to get an artifact's info and it cannot be found" do
    HTTPClient.any_instance.stub(:get).and_raise(NexusCli::ArtifactNotFoundException)
    expect {remote.get_artifact_info "com.something:something:tgz:1.0.0"}.to raise_error(NexusCli::ArtifactNotFoundException)
  end

  it "gives you errors when you attempt to pull an artifact with classifier and it cannot be found" do
    HTTPClient.any_instance.stub(:get).and_raise(NexusCli::ArtifactNotFoundException)
    expect {remote.pull_artifact "com.something:something:tgz:x64:1.0.0", nil}.to raise_error(NexusCli::ArtifactNotFoundException)
  end

  it "gives you an error when you try to update a user that doesnt exist" do
    stub_request(:get, "http://admin:admin123@localhost:8081/nexus/service/local/users/qwertyasdf").
      with(:headers => {
        'Accept' => 'application/json',
        'Authorization' => 'Basic YWRtaW46YWRtaW4xMjM='
      }).to_return(:status => 404, :body => "", :headers => {})

    expect {
      remote.update_user(:userId => "qwertyasdf")
    }.to raise_error(NexusCli::UserNotFoundException)
  end

  it "gives you an error when you try to set the logging level to something weird" do
    expect {remote.set_logger_level("weird")}.to raise_error(NexusCli::InvalidLoggingLevelException)
  end

  it "will return raw xml from the search command" do
    stub_request(:get, "http://admin:admin123@localhost:8081/nexus/service/local/data_index?a=something&g=com.something").to_return(:status => 200, :body => fake_xml, :headers => {})
    remote.search_for_artifacts("com.something:something").should eq fake_xml
  end
end
