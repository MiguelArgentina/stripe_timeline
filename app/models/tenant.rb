# app/models/tenant.rb
class Tenant < ApplicationRecord
  has_many :domains, dependent: :destroy
  has_many :users,   dependent: :destroy
  has_one  :app_setting, dependent: :destroy

  validates :primary_domain, presence: true, uniqueness: true

  after_commit :ensure_app_setting!, on: :create

  # Exact domain first, then primary_domain fallback (both lowercased)
  def self.for_host(host)
    h = host.to_s.downcase
    Domain.includes(:tenant).find_by(host: h)&.tenant || find_by(primary_domain: h)
  end

  # Used when building URLs like root_url(host: tenant.canonical_host)
  def canonical_host
    primary_domain
  end

  # Optional convenience for later:
  def add_domain!(host, make_primary: false)
    d = domains.create!(host: host.downcase)
    update!(primary_domain: d.host) if make_primary || primary_domain.blank?
    d
  end

  private
  def ensure_app_setting!
    app_setting || create_app_setting!(fetch_fees: false)
  end
end
