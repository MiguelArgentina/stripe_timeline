# app/models/stripe_object.rb
class StripeObject < ApplicationRecord
  belongs_to :tenant

  validates :tenant, :object_type, :object_id, presence: true

  # NOTE: now accepts tenant:
  def self.upsert_snapshot!(tenant:, object_type:, object_id:, account:, payload:, last_event_id:)
    obj = find_or_initialize_by(tenant: tenant, object_type: object_type, object_id: object_id)
    obj.assign_attributes(
      account:       account,
      current:       payload,
      last_event_id: last_event_id,
      tenant:        tenant
    )
    obj.save!
    obj
  end
end
