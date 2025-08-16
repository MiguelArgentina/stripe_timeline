class TransactionSummary < ApplicationRecord
  STATUS_RANK = Hash.new(-1).merge(
    "requires_payment_method" => 0,
    "succeeded"               => 10,
    "refunded"                => 20,
    "disputed"                => 30
  ).freeze

  belongs_to :tenant

  validates :transaction_key, presence: true

  # Live updates to the index list
  after_create_commit -> {
    broadcast_prepend_to stream_key,
                         target: "tx_index_list",
                         partial: "transactions/summary_row",
                         locals: { t: self }
  }
  after_update_commit -> {
    broadcast_replace_to stream_key,
                         target: ActionView::RecordIdentifier.dom_id(self),
                         partial: "transactions/summary_row",
                         locals: { t: self }
  }

  def stream_key
    "tx:index:#{tenant_id}"# || Current.tenant&.id || 'global'}"
  end

  def self.rank(status)
    STATUS_RANK[status.to_s]
  end

  # Derive a user-facing status from an event
  def self.derive_status(e, o)
    t = e.type_name

    # Highest-signal event families first
    return "disputed" if t.start_with?("charge.dispute.")
    return "refunded" if t == "charge.refunded" || t.start_with?("refund.")

    # Prefer explicit success signals
    return "succeeded" if t == "payment_intent.succeeded" || t == "charge.succeeded"

    # For PI events, Stripe sends a "status" field you can trust
    if t.start_with?("payment_intent.")
      return (o["status"] || "requires_payment_method")
    end

    # Fallback—be conservative
    o["status"] || "requires_payment_method"
  end

  def self.upsert_from_event(evt)
    payload = evt.payload["data"]["object"]
    key     = evt.transaction_key || TransactionKey.compute(payload)
    return unless key

    ts    = evt.created_at_unix.to_i
    attrs = extract_attrs_from(payload, evt)

    # Lock the row so parallel jobs don't step on each other
    rec = TransactionSummary.lock.find_or_initialize_by(tenant: evt.tenant, transaction_key: key)
    rec.tenant ||= evt.tenant
    rec.events_count = rec.events_count.to_i + 1

    # Only update “latest” fields if this event is as new or newer
    if rec.new_record? || rec.last_event_at_unix.to_i <= ts
      rec.assign_attributes(attrs.merge(last_event_at_unix: ts))
    end

    rec.save!
    rec
  end

  def self.apply_event!(e)
    key        = e.transaction_key
    o          = e.payload.dig("data", "object") || {}
    new_status = derive_status(e, o)

    row = where(tenant: e.tenant).find_or_initialize_by(transaction_key: key)
    row.tenant ||= e.tenant
    row.last_event_at_unix ||= 0
    old_status = row.status

    newer_time   = e.created_at_unix.to_i > row.last_event_at_unix.to_i
    same_time    = e.created_at_unix.to_i == row.last_event_at_unix.to_i
    better_state = rank(new_status) > rank(old_status)

    should_update = newer_time || (same_time && better_state) || row.status.blank?

    return row unless should_update

    email = o.dig("billing_details", "email") ||
            o.dig("charges", "data", 0, "billing_details", "email")
    last4 = o.dig("payment_method_details", "card", "last4") ||
            o.dig("charges", "data", 0, "payment_method_details", "card", "last4")

    row.assign_attributes(
      amount_integer:     amount_for_summary(new_status, o, row.amount_integer),
      currency:           (o["currency"] || row.currency),
      status:             new_status,
      last_event_at_unix: e.created_at_unix.to_i,
      email:              (email || row.email),
      last4:              (last4 || row.last4),
      livemode:           e.livemode
    )
    row.save!
    row
  end

  # How much to show in the index row (keep simple; you can refine later)
  def self.amount_for_summary(status, o, existing_amount)
    case status
    when "refunded"
      refunded = o["amount_refunded"] || o["amount"] || 0
      -refunded
    when "disputed"
      -(o["amount"] || existing_amount || 0)
    else
      o["amount"] || o["amount_captured"] || existing_amount || 0
    end
  end

  def self.extract_attrs_from(o, evt)
    type = o["object"]
    amount, currency, status, latest_pi, latest_charge, email = nil

    case type
    when "payment_intent"
      amount        = o["amount"]
      currency      = o["currency"]
      status        = o["status"]
      latest_pi     = o["id"]
      latest_charge = o["latest_charge"]
      email         = o.dig("shipping","phone").presence || o["receipt_email"] || o.dig("charges","data",0,"billing_details","email")
      meta_order    = o.dig("metadata","order_id")
      customer      = o["customer"]
    when "charge"
      amount        = o["amount"]
      currency      = o["currency"]
      status        = o["status"]
      latest_charge = o["id"]
      latest_pi     = o["payment_intent"]
      email         = o.dig("billing_details","email")
      last4         = o.dig("payment_method_details","card","last4")
      customer      = o["customer"]
      meta_order    = o.dig("metadata","order_id")
    when "refund"
      amount        = -o["amount"] # negative for quick visual
      currency      = o["currency"]
      status        = "refunded"
      latest_charge = o["charge"]
    when "invoice"
      amount        = o["amount_paid"] || o["amount_due"]
      currency      = o["currency"]
      status        = o["status"]
      latest_pi     = o["payment_intent"]
      email         = o["customer_email"]
    when "checkout.session"
      status        = o["status"]
      latest_pi     = o["payment_intent"]
    when "dispute"
      amount   = -o["amount"]           # show as a negative hold
      currency = o["currency"]
      status   = "disputed"             # or o["status"] if you prefer raw states
      latest_charge = o["charge"]
    end

    {
      last_type:   evt.type_name,
      amount_integer: amount,
      currency:    currency,
      status:      status,
      latest_pi:   latest_pi,
      latest_charge: latest_charge,
      email:       email,
      livemode:    evt.livemode,
      account:     evt.account,
      last4: last4 || "",
      order_id: meta_order || "",
      customer_id: customer || "",
    }
  end
end
