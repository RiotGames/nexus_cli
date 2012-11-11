require 'nexus_cli'

describe NexusCli do
  it "gives you errors when configuration has a blank password" do
    overrides = {"url" => "http://somewebsite.com", "username" => "admin", "password" => ""}
    expect {NexusCli::Configuration.parse(overrides)}.to raise_error(NexusCli::InvalidSettingsException)
  end

  it "gives you errors when configuration has a blank username" do
    overrides = {"url" => "http://somewebsite.com", "username" => "", "password" => "admin"}
    expect {NexusCli::Configuration.parse(overrides)}.to raise_error(NexusCli::InvalidSettingsException)
  end

  it "gives you errors when configuration has a blank url" do
    overrides = {"url" => "", "username" => "admin", "password" => "admin"}
    expect {NexusCli::Configuration.parse(overrides)}.to raise_error(NexusCli::InvalidSettingsException)
  end

  it "gives you errors when configuration has a blank repository" do
    overrides = {"url" => "http://somewebsite.com", "repository" => ""}
    expect {NexusCli::Configuration.parse(overrides)}.to raise_error(NexusCli::InvalidSettingsException)
  end
end