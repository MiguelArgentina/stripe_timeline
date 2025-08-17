# app/models/user.rb
class User < ApplicationRecord
  belongs_to :tenant
  has_secure_password

  validates :email, presence: true
  validates :email, uniqueness: { scope: :tenant_id, case_sensitive: false }
end
