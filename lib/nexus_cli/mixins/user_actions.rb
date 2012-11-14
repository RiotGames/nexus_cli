require 'json'
require 'jsonpath'

module NexusCli
  # @author Kyle Allan <kallan@riotgames.com>
  module UserActions


    # Gets information about the current Nexus users.
    # 
    # @return [String] a String of XML with data about Nexus users
    def get_users
      response = nexus.get(nexus_url("service/local/users"))
      case response.status
      when 200
        return response.content
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end
    end

    # Creates a User.
    # 
    # @param  params [Hash] a Hash of parameters to use during user creation
    # 
    # @return [Boolean] true if the user is created, false otherwise
    def create_user(params)
      response = nexus.post(nexus_url("service/local/users"), :body => create_user_json(params), :header => DEFAULT_CONTENT_TYPE_HEADER)
      case response.status
      when 201
        return true
      when 400
        raise CreateUserException.new(response.content)
      else
        raise UnexpectedStatusCodeException.new(reponse.code)
      end
    end

    # Updates a user by changing parts of that user's data.
    # 
    # @param  params [Hash] a Hash of parameters to update
    # 
    # @return [Boolean] true if the user is updated, false otherwise
    def update_user(params)
      params[:roles] = [] if params[:roles] == [""]
      user_json = get_user(params[:userId])

      modified_json = JsonPath.for(user_json)
      params.each do |key, value|
        modified_json.gsub!("$..#{key}"){|v| value} unless key == "userId" || value.blank?
      end

      response = nexus.put(nexus_url("service/local/users/#{params[:userId]}"), :body => JSON.dump(modified_json.to_hash), :header => DEFAULT_CONTENT_TYPE_HEADER)
      case response.status
      when 200
        return true
      when 400
        raise UpdateUserException.new(response.content)
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end
    end

    # Gets a user 
    #
    # @param  user [String] the name of the user to get
    # 
    # @return [Hash] a parsed Ruby object representing the user's JSON
    def get_user(user)
      response = nexus.get(nexus_url("service/local/users/#{user}"), :header => DEFAULT_ACCEPT_HEADER)
      case response.status
      when 200
        return JSON.parse(response.content)
      when 404
        raise UserNotFoundException.new(user)
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end
    end

    # Changes the password of a user
    # 
    # @param  params [Hash] a hash given to update the users password
    # 
    # @return [type] [description]
    def change_password(params)
      response = nexus.post(nexus_url("service/local/users_changepw"), :body => create_change_password_json(params), :header => DEFAULT_CONTENT_TYPE_HEADER)
      case response.status
      when 202
        return true
      when 400
        raise InvalidCredentialsException
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end
    end

    # Deletes the Nexus user with the given id.
    #
    # @param  user_id [String] the Nexus user to delete
    # 
    # @return [Boolean] true if the user is deleted, false otherwise
    def delete_user(user_id)
      response = nexus.delete(nexus_url("service/local/users/#{user_id}"))
      case response.status
      when 204
        return true
      when 404
        raise UserNotFoundException.new(user_id)
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end
    end

    private

    def create_user_json(params)
      JSON.dump(:data => params)
    end

    def create_change_password_json(params)
      JSON.dump(:data => params)
    end
  end
end