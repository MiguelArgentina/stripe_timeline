module StripeEventsHelper
  def event_amount_label(e)
    o = e.payload["data"]["object"] || {}
    case o["object"]
    when "payment_intent"
      amt = o["amount"]; cur = o["currency"]; st = o["status"]
      label = money_cents(amt, cur) if amt && cur
      [label, ("status=#{st}" if st)].compact.join(" ")
    when "charge"
      amt = o["amount"]; cur = o["currency"]; rf = o["amount_refunded"].to_i
      parts = []
      parts << money_cents(amt, cur) if amt && cur
      parts << "refunded #{money_cents(rf, cur)}" if rf.positive?
      parts << "captured" if o["captured"]
      parts.join(" / ")
    when "refund"
      amt = o["amount"]; cur = o["currency"]
      "refund #{money_cents(amt, cur)}" if amt && cur
    when "dispute"
      amt = o["amount"]; cur = o["currency"]; st = o["status"]
      base = "dispute #{money_cents(amt, cur)}" if amt && cur
      [base, ("(#{st})" if st)].compact.join(" ")
    when "dispute_funds" # 👈 derived entries
      dir = o["direction"] # "funds_withdrawn" / "funds_reinstated"
      amt = o["amount"];   cur = o["currency"]
      verb = (dir == "funds_withdrawn" ? "funds withdrawn" : "funds reinstated")
      "#{verb} #{money_cents(amt.abs, cur)}" if amt && cur
    when "invoice"
      amt = o["amount_paid"] || o["amount_due"]; cur = o["currency"]; st = o["status"]
      [money_cents(amt, cur), ("(#{st})" if st)].compact.join(" ") if amt && cur
    else
      nil
    end
  end
end
