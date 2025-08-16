# app/models/tenant.rb
class Tenant < ApplicationRecord
  has_many :domains, dependent: :destroy
  has_one  :app_setting, dependent: :destroy
  validates :primary_domain, presence: true, uniqueness: true
  after_commit :ensure_app_setting!, on: :create

  def self.for_host(host)
    # Exact match first, then primary_domain fallback
    Domain.includes(:tenant).find_by(host: host)&.tenant ||
      find_by(primary_domain: host)
  end
  private
  def ensure_app_setting!
    app_setting || create_app_setting!(fetch_fees: false)
  end
end

