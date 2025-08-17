# app/presenters/transaction_totals.rb
require "set"

class TransactionTotals
  attr_reader :gross, :refunded, :held, :reinstated

  def initialize(events)
    @gross      = 0   # captured charges (unique by charge id)
    @refunded   = 0   # refunds (unique by refund id)
    @held       = 0   # dispute funds withdrawn (unique by dispute id)
    @reinstated = 0   # dispute funds reinstated (unique by dispute id)

    seen_charge_ids           = Set.new
    seen_refund_ids           = Set.new
    seen_dispute_withdrawn    = Set.new
    seen_dispute_reinstated   = Set.new

    Array(events).each do |e|
      o    = e.payload.dig("data", "object") || {}
      type = e.type_name.to_s

      case o["object"]
      when "payment_intent"
        # informational; not money movement
        next

      when "charge"
        # 1) Gross counted exactly once per captured/succeeded charge
        charge_id = o["id"]
        captured  = truthy?(o["captured"]) || o["status"] == "succeeded" || type == "charge.succeeded"
        if charge_id && captured && !seen_charge_ids.include?(charge_id)
          @gross += o["amount"].to_i
          seen_charge_ids << charge_id
        end

        # 2) Some webhooks (e.g., charge.refunded) only include embedded refunds here
        Array(o.dig("refunds", "data")).each do |r|
          rid = r["id"]
          next if rid.nil? || seen_refund_ids.include?(rid)
          @refunded += r["amount"].to_i
          seen_refund_ids << rid
        end

      when "refund"
        # Standalone refund object (refund.created/updated)
        rid = o["id"]
        next if rid.nil? || seen_refund_ids.include?(rid)
        @refunded += o["amount"].to_i
        seen_refund_ids << rid

      when "dispute"
        # Dispute funds movements; dedupe by dispute id + direction
        did = o["id"]
        amt = o["amount"].to_i

        if type.end_with?("funds_withdrawn") || o["status"] == "lost"
          next if did && seen_dispute_withdrawn.include?(did)
          @held += amt
          seen_dispute_withdrawn << did if did
        elsif type.end_with?("funds_reinstated") || o["status"] == "won"
          next if did && seen_dispute_reinstated.include?(did)
          @reinstated += amt
          seen_dispute_reinstated << did if did
        end

      when "dispute_funds"
        # Your derived rows: negative = held, positive = reinstated
        amt = o["amount"].to_i
        amt < 0 ? @held += -amt : @reinstated += amt
      end
    end
  end

  def net
    @gross - @refunded - @held + @reinstated
  end

  private

  def truthy?(v)
    v == true || v == "true" || v == 1 || v == "1"
  end
end
