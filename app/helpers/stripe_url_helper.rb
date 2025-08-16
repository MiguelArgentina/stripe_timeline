# frozen_string_literal: true
module StripeUrlHelper
  def stripe_url_for(id, livemode:)
    base = livemode ? "https://dashboard.stripe.com" : "https://dashboard.stripe.com/test"
    path =
      case id
      when /\Api_/  then "/payments/#{id}"
      when /\Ach_/  then "/payments/#{id}"              # charges live under Payments
      when /\Adp_/  then "/disputes/#{id}"
      when /\Are_/  then "/refunds/#{id}"
      when /\Atxn_/ then "/balance/transactions/#{id}"  # balance tx
      else "/search?query=#{CGI.escape(id.to_s)}"
      end
    "#{base}#{path}"
  end

  # Pick the “primary” object to link for this event
  def primary_dashboard_id_for_event(e)
    o = e.payload["data"]["object"] || {}
    case o["object"]
    when "payment_intent" then o["id"]
    when "charge"         then o["id"]
    when "refund"         then o["id"]                    # has its own page
    when "dispute"        then o["id"]
    when "dispute_funds"  then o["dispute_id"] || o["charge"] # derived row → prefer dispute
    else
      o["id"] || o["latest_charge"] || o["payment_intent"]
    end
  end
end
