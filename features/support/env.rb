require 'aruba/cucumber'
$:.push "#{File.dirname(__FILE__)}/../../lib/"
require 'nexus_cli'
require 'rspec'

def get_overrides_string
  @overrides_string ||= "url:http://localhost:8081/nexus repository:releases username:admin password:admin123"
end

def get_overrides
  @overrides ||= {'url' => 'http://localhost:8081/nexus', 'repository' => 'releases', 'username' => 'deployment', 'password' => 'deployment123'}
end

def temp_dir
  @tmpdir ||= Dir.mktmpdir
end

def nexus_remote
  @nexus_remote ||= NexusCli::Factory.create(get_overrides)
end

at_exit do
  FileUtils.rm_rf(temp_dir)
end