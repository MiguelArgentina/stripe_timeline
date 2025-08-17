# app/models/domain.rb
class Domain < ApplicationRecord
  RESERVED_HOSTS = %w[
    www api admin app assets static files cdn support help status
    mail smtp blog dev test staging demo lvh.me localhost 127.0.0.1
  ].freeze

  belongs_to :tenant

  validates :host, presence: true, uniqueness: true
  validate  :host_not_reserved

  private
  def host_not_reserved
    # In development, allow convenience hosts:
    # - any subdomain on lvh.me, e.g. demo.lvh.me
    # - bare localhost / 127.0.0.1, if you ever use them
    if Rails.env.development?
      return if host.to_s.ends_with?(".lvh.me")
      return if %w[localhost 127.0.0.1].include?(host)
    end

    # In other envs, only block exact reserved hosts (not subdomains)
    if RESERVED_HOSTS.include?(host)
      errors.add(:host, "is reserved")
    end
  end
end
