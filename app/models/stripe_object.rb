# app/models/stripe_object.rb
class StripeObject < ApplicationRecord
  belongs_to :tenant

  # NOTE: ensure you have a UNIQUE index named :uniq_object_snapshot
  # Ideally on [:tenant_id, :object_type, :object_id] (migration below).

  def self.upsert_snapshot!(tenant:, object_type:, object_id:, payload:, event_id:, account: nil)
    data = {
      tenant_id:     tenant.id,
      object_type:   object_type,
      object_id:     object_id,
      account:       account.to_s,
      current:       payload,
      last_event_id: event_id,
      updated_at:    Time.current,
      created_at:    Time.current
    }

    # Atomic: INSERT … ON CONFLICT DO UPDATE
    upsert(data, unique_by: :uniq_object_snapshot)
  end
end
