require 'aruba/api'
World(Aruba::Api)

When /^I call the nexus "(.*?)" command$/ do |command|
  step "I run `nexus-cli #{command} --overrides=#{get_overrides_string}`"
end

When /^I push an artifact with the GAV of "(.*)"$/ do |gav|
  groupId, artifactId, version, extension = gav.split(":")
  file = File.new(File.join(temp_dir, "#{artifactId}-#{version}.#{extension}"), 'w')
  file.puts "some data"
  file.close
  step "I run `nexus-cli push #{gav} #{file.path} --overrides=#{get_overrides_string}`"
end

When /^I pull an artifact with the GAV of "(.*?)" to a temp directory$/ do |gav|
  step "I run `nexus-cli pull #{gav} --destination #{temp_dir} --overrides=#{get_overrides_string}`"
end

Then /^I should have a copy of the "(.*?)" artifact in a temp directory$/ do |fileName|
  File.exists?(File.join(temp_dir, fileName)).should == true
end

When /^I delete an artifact with the GAV of "(.*)"$/ do |gav|
  nexus_remote.delete_artifact(gav)
end