# app/models/stripe_relation.rb
class StripeRelation < ApplicationRecord
  belongs_to :tenant
  def self.link!(from_type:, from_id:, to_type:, to_id:, relation:, account:)
    create!(from_type:, from_id:, to_type:, to_id:, relation:, account:)
  rescue ActiveRecord::RecordNotUnique
    # idempotent
  end
end