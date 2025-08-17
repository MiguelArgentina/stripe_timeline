# app/controllers/sessions_controller.rb
class SessionsController < ApplicationController
  skip_before_action :require_login, only: [:new, :create]

  def new; end

  def create
    user = Current.tenant&.users&.find_by(email: params[:email])
    if user&.authenticate(params[:password])
      session[:user_id] = user.id
      redirect_to root_path, notice: "Signed in"
    else
      redirect_to new_session_path, alert: "Invalid email or password"
    end
  end

  def destroy
    reset_session
    redirect_to new_session_path, notice: "Signed out"
  end
end
