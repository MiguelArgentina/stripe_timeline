# frozen_string_literal: true
require "test_helper"

class StripeRelationTest < ActiveSupport::TestCase
  def tenant
    Tenant.take || skip("needs at least one Tenant in the DB")
  end

  test "enforces uniqueness per tenant on relations graph" do
    attrs = {
      tenant_id: tenant.id,
      from_type: "payment_intent", from_id: "pi_x",
      to_type: "charge",           to_id: "ch_y",
      relation: "pi→charge",
      account: "" # not NULL, so unique index bites
    }

    StripeRelation.create!(attrs)
    assert_raises(ActiveRecord::RecordNotUnique) { StripeRelation.create!(attrs) }
  end
end
