require 'aruba/api'
require 'json'
require 'jsonpath'
World(Aruba::Api)

When /^I call the nexus "(.*?)" command$/ do |command|
  step "I run `nexus-cli #{command} --overrides=#{get_overrides_string}`"
end

When /^I call the nexus "(.*?)" command as the "(.*?)" user with password "(.*?)"$/ do |command, username, password|
  overrides = get_overrides_string.gsub('username:admin', "username:#{username}")
  overrides.gsub!('password:admin123', "password:#{password}")
  step "I run `nexus-cli #{command} --overrides=#{overrides}`"
end

When /^I push an artifact with the GAV of "(.*)"$/ do |gav|
  groupId, artifact_id, version, extension = gav.split(":")
  file = File.new(File.join(temp_dir, "#{artifact_id}-#{version}.#{extension}"), 'w')
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

When /^I edit the "(.*?)" files "(.*?)" field to true$/ do |file, field|
  Dir.chdir('tmp/aruba') do
    json = JSON.parse(File.read(File.join(File.expand_path("~/.nexus"), file)))
    File.open(File.join(File.expand_path("~/.nexus"), file), "w+") do |opened|
      json["data"]["globalRestApiSettings"][field] = true
      opened.write(JSON.pretty_generate(json))
    end
  end
end

When /^I update global settings uiTimeout to (\d+) and upload the json string$/ do |value|  
  json = JSON.parse(nexus_remote.get_global_settings_json)
  edited_json = JsonPath.for(json).gsub("$..uiTimeout") {|v| value.to_i}.to_hash
  nexus_remote.upload_global_settings(JSON.dump(edited_json))
end

When /^I add a trusted key to nexus$/ do
  Dir.chdir(temp_dir) do
    File.open("cert.txt", "w+") do |opened|
      opened.write("-----BEGIN CERTIFICATE-----
MIICiTCCAfICCQDIKBRH7YO5mTANBgkqhkiG9w0BAQUFADCBiDELMAkGA1UEBhMC
VVMxEzARBgNVBAgTCkNhbGlmb3JuaWExFTATBgNVBAcTDFNhbnRhIE1vbmljYTET
MBEGA1UEChMKUmlvdCBHYW1lczETMBEGA1UEAxMKS3lsZSBBbGxhbjEjMCEGCSqG
SIb3DQEJARYUa2FsbGFuQHJpb3RnYW1lcy5jb20wHhcNMTIwNjIwMjMxOTQ1WhcN
MTMwNjIwMjMxOTQ1WjCBiDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCkNhbGlmb3Ju
aWExFTATBgNVBAcTDFNhbnRhIE1vbmljYTETMBEGA1UEChMKUmlvdCBHYW1lczET
MBEGA1UEAxMKS3lsZSBBbGxhbjEjMCEGCSqGSIb3DQEJARYUa2FsbGFuQHJpb3Rn
YW1lcy5jb20wgZ8wDQYJKoZIhvcNAQEBBQADgY0AMIGJAoGBAM8Yz96KDxzv7eEt
DQNLV/3ipXJ5U/lQOQ2BrjSB6qrAHP2u4f+tzJtANXHcRrhXI3oOE993fg82adZg
XpWLl9wcPHDKP8s5l4TUxMjVJ4UYLJeINwOh/s3cpFq/ni/Klb+QWKG8Vyp6ossF
VGOc0IiU4ZaC38+jlqvCkHwdCQ4hAgMBAAEwDQYJKoZIhvcNAQEFBQADgYEAG6Eh
2QO0D69W+9wFvMQAC8YvHNMW9S9A+YRDa5vOeWzUZpeAYuawFSVfjT3fof2ovCU8
/AR2PyVwJvXRp0Yon2sUfaaFVP4x0BFAwWHk4vLBtqviBhKRdF1D/rR1g4KRowsh
P5KVneepzhtEt9G/uO4MU89cdUR0IMyUwdhq2dg=
-----END CERTIFICATE-----
")
    end
    step "I run `nexus-cli add_trusted_key --certificate=#{File.join(temp_dir, "cert.txt")} --description=cucumber --overrides=#{get_overrides_string}`"
  end
end

When /^I delete a trusted key in nexus$/ do
  json = JSON.parse(nexus_remote.get_trusted_keys)
  key_id = json["data"].first["id"]
  step "I run `nexus-cli delete_trusted_key #{key_id} --overrides=#{get_overrides_string}`"
end

Then /^a file named "(.*?)" should exist in my nexus folder$/ do |file|
  path = File.join(File.expand_path("~/.nexus"), file)
  step "a file named \"#{path}\" should exist"
end

Then /^the file "(.*?)" in my nexus folder should contain:$/ do |file, partial_content|
  path = File.join(File.expand_path("~/.nexus"), file)
  check_file_content(path, partial_content, true)
end

Then /^the file "([^"]*)" should contain:$/ do |file, partial_content|
  check_file_content(file, partial_content, true)
end
