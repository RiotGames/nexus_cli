module NexusCli
  # @return [String]
  def self.version
    @version ||= File.read(File.expand_path("../../../VERSION", __FILE__)).strip
  end
end