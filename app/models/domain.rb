# app/models/domain.rb
class Domain < ApplicationRecord
  belongs_to :tenant
  validates :host, presence: true, uniqueness: true
end