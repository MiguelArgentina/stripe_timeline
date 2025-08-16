class DisputeFunds
  # Creates synthetic StripeEvent rows for money movement on a dispute:
  # - charge.dispute.funds_withdrawn  (amount < 0)
  # - charge.dispute.funds_reinstated (amount > 0)
  #
  # It keys them by dispute_id + balance_tx_id so they are idempotent.

  def self.sync!(evt)
    o = evt.payload["data"]["object"] || {}
    return unless o["object"] == "dispute"

    dispute = ensure_balance_transactions(o)

    (dispute["balance_transactions"] || []).each do |bt|
      dir = bt["amount"].to_i < 0 ? "funds_withdrawn" : "funds_reinstated"
      type_name = "charge.dispute.#{dir}"
      stripe_id = "drv:#{dispute['id']}:#{bt['id']}:#{dir}"  # synthetic, stable

      next if StripeEvent.exists?(stripe_id: stripe_id)

      tx_key = evt.transaction_key || TransactionKey.compute(dispute)
      payload = {
        "object" => "dispute_funds",
        "direction" => dir,
        "amount" => bt["amount"],
        "currency" => bt["currency"],
        "balance_transaction_id" => bt["id"],
        "dispute_id" => dispute["id"],
        "charge" => dispute["charge"]
      }

      se = StripeEvent.create!(
        stripe_id: stripe_id,
        type_name: type_name,
        api_version: evt.api_version,
        account: evt.account,
        livemode: evt.livemode,
        created_at_unix: bt["created"] || evt.created_at_unix,
        source: "derived",
        transaction_key: tx_key,
        payload: { "data" => { "object" => payload } }
      )

      # Optional relations
      StripeRelation.link!(from_type: "dispute", from_id: dispute["id"],
                           to_type: "balance_transaction", to_id: bt["id"],
                           relation: "dispute↔balance_tx", account: evt.account) rescue nil
    end
  end

  # If webhook didn’t include balance_transactions, fetch with expand.
  def self.ensure_balance_transactions(dispute_hash)
    if dispute_hash["balance_transactions"].present?
      return dispute_hash
    end
    begin
      full = Stripe::Dispute.retrieve(
        dispute_hash["id"],
        { expand: ["balance_transactions"] }
      )
      full.respond_to?(:to_hash) ? full.to_hash : full
    rescue => _
      dispute_hash # fallback
    end
  end
end
