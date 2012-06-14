When /^I get the artifact "([^"]*)"$/ do |arg1|
  NexusCli::Remote.pull_artifact arg1, nil
end

Then /^I should have a copy of the "([^"]*)" artifact on my computer$/ do |arg1|
  File.exists?(arg1).should be_true
end

When /^I want the artifact "([^"]*)" in a temp directory$/ do |arg1|
  NexusCli::Remote.pull_artifact arg1, ENV["TMPDIR"]
end

Then /^I should have a copy of the "([^"]*)" artifact in a temp directory$/ do |arg1|
  path = File.join(ENV["TMPDIR"], arg1)
  File.exists?(path).should be_true
end

Then /^I should expect an error because I need more colon separated values$/ do
    assert_exit_status(100)
end

When /^I push an artifact into the Nexus$/ do
  file = File.new("myFile.tgz", 'w')
  file.puts "some data"
  file.close
  file = File.open("myFile.tgz", 'r')
  NexusCli::Remote.push_artifact "com.foo.bar:myFile:1.0.0:tgz", file
end

Then /^I should be able to ask the Nexus for information about it and get a result$/ do
  NexusCli::Remote.get_artifact_info "com.foo.bar:myFile:1.0.0:tgz"
end