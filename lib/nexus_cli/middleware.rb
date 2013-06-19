Dir["#{File.dirname(__FILE__)}/middleware/*.rb"].sort.each do |path|
  require_relative "middleware/#{File.basename(path, '.rb')}"
end
