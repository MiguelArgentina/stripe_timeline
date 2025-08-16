# app/controllers/stripe/webhooks_controller.rb
class Stripe::WebhooksController < ApplicationController
  skip_forgery_protection

  def receive
    # 1) Resolve tenant from host (via ApplicationController)
    raise ActiveRecord::RecordNotFound, "Tenant not found for host #{request.host}" if Current.tenant.nil?

    raw = request.raw_post
    sig = request.headers["Stripe-Signature"]

    # 2) Parse once so we can keep a Hash in DB (cheaper to render later)
    payload_hash = JSON.parse(raw)

    # 3) Verify signature with the TENANT’S webhook secret
    secret = Current.tenant.webhook_signing_secret.presence || ENV["STRIPE_WEBHOOK_SECRET"]
    event  = Stripe::Webhook.construct_event(raw, sig, secret)

    # 4) Compute our transaction key
    tx_key = TransactionKey.compute(payload_hash["data"]["object"])

    # 5) Upsert event (scoped to tenant)
    rec = StripeEvent.find_or_initialize_by(stripe_id: event.id)
    if rec.new_record?
      rec.assign_attributes(
        tenant:          Current.tenant,
        type_name:       event.type,
        api_version:     event.api_version,
        account:         (event.respond_to?(:account) ? event.account : nil),
        livemode:        event.livemode,
        created_at_unix: event.created,
        source:          "webhook",
        payload:         payload_hash,   # store plain Hash
        transaction_key: tx_key
      )
      rec.save!
      ProcessStripeEventJob.perform_later(rec.id)  # job will also scope by rec.tenant
    end

    head :ok
  rescue JSON::ParserError, Stripe::SignatureVerificationError => e
    Rails.logger.warn("Stripe webhook verify failed: #{e.class} - #{e.message}")
    head :bad_request
  end
end
