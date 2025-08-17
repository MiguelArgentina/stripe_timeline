# app/controllers/stripe/webhooks_controller.rb
class Stripe::WebhooksController < ApplicationController
  skip_forgery_protection
  skip_before_action :require_login
  skip_before_action :require_tenant! rescue nil
  before_action :assign_tenant!

  def receive
    # Use tenant-specific secret (fallback to env in dev if you want)
    secret = Current.tenant&.webhook_signing_secret.presence || ENV['STRIPE_WEBHOOK_SECRET']

    raw = request.raw_post
    sig = request.headers['Stripe-Signature']

    # Verify against raw payload
    event = Stripe::Webhook.construct_event(raw, sig, secret)

    # Parse once for normalized storage
    payload_hash = JSON.parse(raw)

    tx_key = TransactionKey.compute(payload_hash["data"]["object"])

    rec = StripeEvent.find_or_initialize_by(stripe_id: event.id, tenant: Current.tenant)
    if rec.new_record?
      rec.assign_attributes(
        type_name:       event.type,
        api_version:     event.api_version,
        account:         (event.respond_to?(:account) ? event.account.to_s : ''),
        livemode:        event.livemode,
        created_at_unix: event.created,
        source:          "webhook",
        payload:         payload_hash,
        transaction_key: tx_key
      )
      rec.save!
      ProcessStripeEventJob.perform_later(rec.id)
    end

    head :ok
  rescue JSON::ParserError, Stripe::SignatureVerificationError => e
    Rails.logger.warn("Stripe webhook verify failed: #{e.class} - #{e.message}")
    head :bad_request
  end

  private

  def assign_tenant!
    # Route by subdomain host, e.g. tucu.lvh.me
    Current.tenant = Tenant.for_host(request.host)

    # In production, reject unknown hosts
    if Current.tenant.nil? && !Rails.env.development?
      head :not_found and return
    end

    # In dev, you MAY fallback if you like (optional):
    Current.tenant ||= Tenant.first if Rails.env.development?
  end
end
