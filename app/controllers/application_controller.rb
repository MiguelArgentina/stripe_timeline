class ApplicationController < ActionController::Base
  before_action :set_current_tenant
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  private
  def set_current_tenant
    host = request.host
    Current.tenant =
      Domain.includes(:tenant).find_by(host:)&.tenant
  end

  def default_url_options
    # make URL helpers generate links on the current tenant host
    { host: Current.tenant&.primary_domain || request.host, protocol: request.protocol }
  end
end
