# app/models/stripe_relation.rb
class StripeRelation < ApplicationRecord
  self.table_name = "stripe_relations"

  # Accept tenant or tenant_id; require one
  def self.link!(from_type:, from_id:, to_type:, to_id:, relation:, account: nil, tenant: nil, tenant_id: nil)
    tid = tenant_id || tenant&.id
    raise ArgumentError, "tenant or tenant_id required" unless tid

    attrs = {
      tenant_id: tid,
      from_type: from_type,
      from_id:   from_id,
      to_type:   to_type,
      to_id:     to_id,
      relation:  relation,
      account:   account.to_s
    }

    # Idempotent insert keyed by :uniq_relations_graph
    insert_all([attrs], unique_by: :uniq_relations_graph)
    true
  end
end
