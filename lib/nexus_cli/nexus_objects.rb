Dir["#{File.dirname(__FILE__)}/nexus_objects/*.rb"].sort.each do |path|
  require_relative "nexus_objects/#{File.basename(path, '.rb')}"
end
