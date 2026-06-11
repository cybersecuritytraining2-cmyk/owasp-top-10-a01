module Api
  class SessionsController < ApplicationController
    # POST /api/login — exchange username + password for a bearer token.
    def create
      user = Store::USERS.values.find { |u| u[:username] == params[:username].to_s }

      unless user && ActiveSupport::SecurityUtils.secure_compare(user[:password], params[:password].to_s)
        Store.log("WARN  auth — login failed user=#{params[:username]} ip=#{request.remote_ip}")
        return render json: { error: "Invalid username or password" }, status: :unauthorized
      end

      if user[:blocked]
        return render json: { error: "This account has been blocked. Contact support." }, status: :forbidden
      end

      token = SecureRandom.hex(24)
      Store::SESSIONS[token] = user[:id]
      Store.log("INFO  auth — login success user=#{user[:username]} ip=#{request.remote_ip}")

      render json: { token: token, user: user_json(user) }
    end

    # POST /api/logout — invalidate the current token.
    def destroy
      Store::SESSIONS.delete(bearer_token)
      head :no_content
    end
  end
end
