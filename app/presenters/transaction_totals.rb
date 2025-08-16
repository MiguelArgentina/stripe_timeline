# app/presenters/transaction_totals.rb
class TransactionTotals
  attr_reader :gross, :refunded, :held, :reinstated, :net

  def initialize(events)
    @gross = @refunded = @held = @reinstated = 0
    events.each do |e|
      o = e.payload["data"]["object"] || {}
      case o["object"]
      when "charge"
        @gross += o["amount"].to_i
      when "refund"
        @refunded += o["amount"].to_i
      when "dispute_funds" # your derived items
        amt = o["amount"].to_i
        amt < 0 ? @held += -amt : @reinstated += amt
      end
    end
    @net = @gross - @refunded - @held + @reinstated
  end
end
