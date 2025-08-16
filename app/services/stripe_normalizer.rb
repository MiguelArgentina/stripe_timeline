class StripeNormalizer
  def self.normalize(evt)
    o = evt.payload["data"]["object"]
    account = evt.account
    type = o["object"]
    oid  = o["id"]
    edges = []

    case type
    when "payment_intent"
      (o.dig("charges", "data") || []).each do |ch|
        edges << { from_type: "payment_intent", from_id: oid, to_type: "charge", to_id: ch["id"], relation: "pi→charge" }
      end
      if pm = o["payment_method"]
        edges << { from_type: "payment_intent", from_id: oid, to_type: "payment_method", to_id: pm, relation: "pi→payment_method" }
      end
    when "charge"
      if pi = o["payment_intent"]
        edges << { from_type: "payment_intent", from_id: pi, to_type: "charge", to_id: oid, relation: "pi→charge" }
      end
      (o.dig("refunds","data") || []).each do |rf|
        edges << { from_type: "charge", from_id: oid, to_type: "refund", to_id: rf["id"], relation: "charge→refund" }
      end
      if bt = o["balance_transaction"]
        edges << { from_type: "charge", from_id: oid, to_type: "balance_transaction", to_id: bt, relation: "charge→balance_tx" }
      end
      if dp = o["dispute"]
        edges << { from_type: "charge", from_id: oid, to_type: "dispute", to_id: dp, relation: "charge→dispute" }
      end
    when "refund"
      if ch = o["charge"]
        edges << { from_type: "charge", from_id: ch, to_type: "refund", to_id: oid, relation: "charge→refund" }
      end
      if bt = o["balance_transaction"]
        edges << { from_type: "refund", from_id: oid, to_type: "balance_transaction", to_id: bt, relation: "refund→balance_tx" }
      end
    when "invoice"
      if pi = o["payment_intent"]
        edges << { from_type: "invoice", from_id: oid, to_type: "payment_intent", to_id: pi, relation: "invoice→pi" }
      end
      if sub = o["subscription"]
        edges << { from_type: "invoice", from_id: oid, to_type: "subscription", to_id: sub, relation: "invoice→subscription" }
      end
    when "checkout.session"
      if pi = o["payment_intent"]
        edges << { from_type: "checkout_session", from_id: oid, to_type: "payment_intent", to_id: pi, relation: "cs→pi" }
      end
      if sub = o["subscription"]
        edges << { from_type: "checkout_session", from_id: oid, to_type: "subscription", to_id: sub, relation: "cs→subscription" }
      end
    end
    edges.uniq! { |e| [e[:from_type], e[:from_id], e[:to_type], e[:to_id], e[:relation]] }
    { object_type: type, object_id: oid, account:, edges:, transaction_key: TransactionKey.compute(o) }
  end
end
