module NexusCli
  # @author Kyle Allan <kallan@riotgames.com>
  module LoggingActions
    
    # Gets information about the current logging
    # levels in Nexus.
    # 
    # 
    # @return [String] a String of JSON representing the current logging levels of Nexus
    def get_logging_info
      response = nexus.get(nexus_url("service/siesta/logging/loggers"), :header => DEFAULT_ACCEPT_HEADER)
      case response.status
        when 200
          data = Hash.new()
          JSON.parse(response.content).each do |entry|
            data["#{entry['name']}"] = "#{entry['level']}"
          end
          return JSON.dump(data)
        else
          raise UnexpectedStatusCodeException.new(response.status)
      end
    end


    # Sets the logging level of Nexus to one of
    # "TRACE" "DEBUG" "INFO" "WARN" "ERROR" "OFF" or "DEFAULT".
    # 
    # @param  name [String] logger to configure
    # @param  level [String] the logging level to set
    #
    # @return [Boolean] true if the logging level has been set, false otherwise
    def set_logger_level(name, level)
      raise InvalidLoggingLevelException unless %w(TRACE DEBUG INFO WARN ERROR OFF DEFAULT).include?(level.upcase)
      response = nexus.post(nexus_url("service/siesta/logging/loggers"), :body => create_logger_level_json(name, level), :header => DEFAULT_CONTENT_TYPE_HEADER)
      case response.status
      when 200
        return true
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end
    end

    private

    def create_logger_level_json(name, level)
      params = {:name => name}
      params[:level] = level.upcase
      JSON.dump(params)
    end
  end
end