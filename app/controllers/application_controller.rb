class ApplicationController < ActionController::Base
  before_action :set_current_tenant
  before_action :accept_cross_subdomain_token   # ← new: consumes ?token=... on tenant host
  before_action :require_tenant!
  before_action :require_login

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  helper_method :current_user

  private

  def set_current_tenant
    Current.tenant = Tenant.for_host(request.host)
  end

  # NEW: one-time cross-subdomain login handoff
  def accept_cross_subdomain_token
    return unless params[:token].present?
    user = User.find_signed(params[:token], purpose: "cross-subdomain-login")
    if user && Current.tenant && user.tenant_id == Current.tenant.id
      session[:user_id] = user.id
      # Clean the URL after accepting the token
      redirect_to request.path, allow_other_host: false
    end
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    # Ignore bad/expired tokens; user will be treated as unauthenticated
  end

  def default_url_options
    # make URL helpers generate links on the current tenant host
    { host: Current.tenant&.primary_domain || request.host, protocol: request.protocol }
  end

  def current_user
    @current_user ||= (Current.tenant && session[:user_id] && User.find_by(id: session[:user_id], tenant: Current.tenant))
  end

  def require_login
    return if controller_path.start_with?("sessions") || controller_path.start_with?("registrations")
    return if action_name.in?(%w[health check]) # if you have public endpoints
    unless current_user
      redirect_to new_session_url(host: request.host), alert: "Please sign in"
    end
  end

  def require_tenant!
    # allow access to signup/login on apex host
    return if controller_path.start_with?("sessions") || controller_path.start_with?("registrations")
    redirect_to new_registration_url(host: request.host), alert: "Create your account" if Current.tenant.nil?
  end
end
