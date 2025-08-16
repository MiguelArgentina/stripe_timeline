# app/jobs/process_stripe_event_job.rb
class ProcessStripeEventJob < ApplicationJob
  queue_as :default

  def perform(event_id)
    evt = StripeEvent.find(event_id)

    # ✅ Set tenant context for the whole job run
    Current.tenant = evt.tenant
    tenant_id = evt.tenant_id

    norm = StripeNormalizer.normalize(evt)

    StripeObject.upsert_snapshot!(
      object_type:   norm[:object_type],
      object_id:     norm[:object_id],
      account:       norm[:account],
      payload:       evt.payload["data"]["object"],
      last_event_id: evt.stripe_id,
      tenant:        evt.tenant                       # ✅
    )

    norm[:edges].each do |e|
      StripeRelation.link!(
        from_type: e[:from_type], from_id: e[:from_id],
        to_type:   e[:to_type],   to_id:   e[:to_id],
        relation:  e[:relation],
        account:   norm[:account],
        tenant:    evt.tenant                         # ✅
      )
    end

    if evt.transaction_key.blank? && norm[:transaction_key].present?
      evt.update!(transaction_key: norm[:transaction_key])
    elsif evt.transaction_key.blank?
      key = TransactionKey.compute(evt.payload["data"]["object"])
      evt.update!(transaction_key: key) if key
    end

    # 🛰️ First broadcast (namespaced with tenant)
    if evt.transaction_key.present?
      events = StripeEvent.where(tenant_id: tenant_id, transaction_key: evt.transaction_key)
                          .order(:created_at_unix)
      Turbo::StreamsChannel.broadcast_replace_to(
        "tx:#{tenant_id}:#{evt.transaction_key}",     # ✅ namespaced
        target:  "timeline",
        partial: "transactions/events",
        locals:  { events: events }
      )
    end

    TransactionSummary.upsert_from_event(evt)         # make sure this sets row.tenant
    if evt.payload.dig("data", "object", "object") == "dispute"
      DisputeFunds.sync!(evt)                         # ensure it writes tenant too
    end
    TransactionSummary.apply_event!(evt)              # ensure it scopes by e.tenant

    # 🛰️ Final broadcast (after summary update)
    if evt.transaction_key.present?
      events = StripeEvent.where(tenant_id: tenant_id, transaction_key: evt.transaction_key)
                          .order(:created_at_unix)
      Turbo::StreamsChannel.broadcast_replace_to(
        "tx:#{tenant_id}:#{evt.transaction_key}",     # ✅ namespaced
        target:  "timeline",
        partial: "transactions/events",
        locals:  { events: events }
      )
    end
  ensure
    Current.reset
  end
end
