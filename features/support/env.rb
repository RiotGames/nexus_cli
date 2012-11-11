require 'rubygems'
require 'bundler'
require 'spork'

module ArubaOverrides
  def detect_ruby(cmd)
    processor, platform, *rest = RUBY_PLATFORM.split("-")
    if platform =~ /w32$/ && cmd =~ /^nexus-cli /
      "ruby -I../../lib -S ../../bin/#{cmd}"
    else
      "#{cmd}"
    end
  end
end

Spork.prefork do
  require 'aruba/cucumber'
  require 'nexus_cli'
  require 'rspec'

  World(ArubaOverrides)

  Before do
    @aruba_timeout_seconds = 10
  end

  def get_overrides_string
    @overrides_string ||= "url:http://localhost:8081/nexus repository:releases username:admin password:admin123"
  end

  def get_overrides
    @overrides ||= {'url' => 'http://localhost:8081/nexus', 'repository' => 'releases', 'username' => 'admin', 'password' => 'admin123'}
  end

  def create_step_overrides(overrides)
    overrides_hash = overrides.split(" ").inject({}) do |overrides_hash, override|
      key, value = override.split(":")
      overrides_hash[key] = value
      overrides_hash
    end

    step_overrides = get_overrides.merge(overrides_hash)
    step_overrides.to_a.inject("") do |overrides_string, pair|
      overrides_string << pair.join(":")
      overrides_string << " "
    end
  end

  def temp_dir
    @tmpdir ||= Dir.mktmpdir
  end

  def nexus_remote
    @nexus_remote ||= NexusCli::RemoteFactory.create(get_overrides)
  end

  at_exit do
    FileUtils.rm_rf(temp_dir)
  end
end

Spork.each_run do
  require 'nexus_cli'
end
