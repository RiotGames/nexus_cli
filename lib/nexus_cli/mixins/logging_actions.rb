module NexusCli
  # @author Kyle Allan <kallan@riotgames.com>
  module LoggingActions
    
    # Gets information about the current logging
    # levels in Nexus.
    # 
    # 
    # @return [String] a String of JSON representing the current logging levels of Nexus
    def get_logging_info
      response = nexus.get(nexus_url("service/local/log/config"), :header => DEFAULT_ACCEPT_HEADER)
      case response.status
      when 200
        return response.content
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end
    end


    # Sets the logging level of Nexus to one of
    # "INFO", "DEBUG", or "ERROR".
    # 
    # @param  level [String] the logging level to set
    # 
    # @return [Boolean] true if the logging level has been set, false otherwise
    def set_logger_level(level)
      raise InvalidLoggingLevelException unless ["INFO", "DEBUG", "ERROR"].include?(level.upcase)
      response = nexus.put(nexus_url("service/local/log/config"), :body => create_logger_level_json(level), :header => DEFAULT_CONTENT_TYPE_HEADER)
      case response.status
      when 200
        return true
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end
    end

    private

    def create_logger_level_json(level)
      params = {:rootLoggerLevel => level.upcase}
      JSON.dump(:data => params)
    end
  end
end