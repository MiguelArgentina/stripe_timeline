# frozen_string_literal: true
require "test_helper"

class TransactionSummaryTest < ActiveSupport::TestCase
  def tenant
    # use an existing tenant so we don't guess required fields
    Tenant.take || skip("needs at least one Tenant in the DB")
  end

  def make_evt(type_name:, status:, ts:)
    payload = {
      "data" => {
        "object" => {
          "object" => "payment_intent",
          "id" => "pi_test",
          "status" => status,
          "amount" => 2000,
          "currency" => "usd"
        }
      }
    }

    StripeEvent.new(
      tenant: tenant,
      type_name: type_name,
      payload: payload,
      created_at_unix: ts,
      transaction_key: "pi_test",
      livemode: false
    )
  end

  test "prefers better status when timestamps tie" do
    worse  = make_evt(type_name: "payment_intent.created",   status: "requires_payment_method", ts: 100)
    better = make_evt(type_name: "payment_intent.succeeded", status: "succeeded",               ts: 100)

    TransactionSummary.apply_event!(worse)
    row = TransactionSummary.apply_event!(better)

    assert_equal "succeeded", row.status
    assert_equal 100, row.last_event_at_unix
  end

  test "dispute/refund families outrank generic success" do
    ok = make_evt(type_name: "payment_intent.succeeded", status: "succeeded", ts: 100)
    TransactionSummary.apply_event!(ok)

    dispute_evt = StripeEvent.new(
      tenant: tenant,
      type_name: "charge.dispute.created",
      payload: { "data" => { "object" => { "object" => "dispute", "id" => "dp_test", "amount" => 2000, "currency" => "usd", "charge" => "ch_123" } } },
      created_at_unix: 101,
      transaction_key: "pi_test",
      livemode: false
    )

    row = TransactionSummary.apply_event!(dispute_evt)
    assert_equal "disputed", row.status
  end
end
