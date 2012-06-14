require 'aruba/cucumber'

$:.push "#{File.dirname(__FILE__)}/../../lib/"
require 'nexus_cli'
require 'rspec'

After do |scenario|
  FileUtils.rm_f("mytar-1.0.3.tgz")

  tmp_path = File.join(ENV["TMPDIR"], "mytar-1.0.3.tgz")
  FileUtils.rm_f(tmp_path)

  NexusCli::Remote.delete_artifact('com.foo.bar:myFile:1.0.0:tgz')
  FileUtils.rm_f("myFile.tgz")
end
