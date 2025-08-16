class TransactionKey
  def self.compute(obj)
    h = obj.respond_to?(:to_hash) ? obj.to_hash : obj # Stripe::* or Hash
    type = h["object"]

    case type
    when "payment_intent"
      h["id"]
    when "charge"
      h["payment_intent"] || h["id"]
    when "refund", "dispute"
      charge_id = h["charge"]
      charge_to_pi(charge_id)
    else
      nil
    end
  end

  def self.charge_to_pi(charge_id)
    return nil if charge_id.blank?
    so = StripeObject.find_by(object_type: "charge", object_id: charge_id)
    return nil unless so

    current = so.current.is_a?(String) ? JSON.parse(so.current) : so.current
    current["payment_intent"]
  rescue JSON::ParserError
    nil
  end
end
