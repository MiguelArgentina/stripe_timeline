# test/presenters/transaction_totals_test.rb
require "test_helper"

class TransactionTotalsTest < ActiveSupport::TestCase
  Event = Struct.new(:type_name, :payload)

  def ev(type, object_hash)
    Event.new(type, { "data" => { "object" => object_hash } })
  end

  test "handles single captured charge" do
    events = [
      ev("charge.succeeded", { "object" => "charge", "id" => "ch_1", "amount" => 2000, "captured" => true })
    ]

    t = TransactionTotals.new(events)
    assert_equal 2000, t.gross
    assert_equal 0,    t.refunded
    assert_equal 0,    t.held
    assert_equal 0,    t.reinstated
    assert_equal 2000, t.net
  end

  test "dedupes refund and does not double-count gross when both charge.refunded and refund.created are present" do
    refund = { "object" => "refund", "id" => "re_1", "amount" => 700 }
    charge_with_refund = {
      "object" => "charge", "id" => "ch_1", "amount" => 2000, "captured" => true,
      "refunds" => { "data" => [refund] }
    }

    events = [
      ev("charge.succeeded", charge_with_refund),
      ev("charge.refunded",  charge_with_refund), # same charge again (should NOT double count gross)
      ev("refund.created",   refund)              # same refund again (should NOT double count refund)
    ]

    t = TransactionTotals.new(events)
    assert_equal 2000, t.gross,     "gross must be counted only once"
    assert_equal 700,  t.refunded,  "refund should be counted once via id-dedupe"
    assert_equal 1300, t.net
  end

  test "counts dispute funds withdrawn and reinstated correctly" do
    events = [
      ev("charge.succeeded", { "object" => "charge", "id" => "ch_1", "amount" => 2000, "captured" => true }),
      ev("charge.dispute.funds_withdrawn",  { "object" => "dispute", "id" => "dp_1", "amount" => 2000 }),
      ev("charge.dispute.funds_reinstated", { "object" => "dispute", "id" => "dp_1", "amount" => 500 })
    ]

    t = TransactionTotals.new(events)
    assert_equal 2000, t.gross
    assert_equal 2000, t.held
    assert_equal 500,  t.reinstated
    assert_equal 500,  t.net
  end
end
