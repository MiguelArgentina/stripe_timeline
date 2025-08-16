# frozen_string_literal: true

class AddUniqsAndIndexes < ActiveRecord::Migration[7.1]
  def change
    add_index :stripe_relations,
              [:from_type, :from_id, :to_type, :to_id, :relation, :account],
              unique: true, name: "uniq_relations_graph"

    add_index :stripe_events, :stripe_id, unique: true
    add_index :stripe_events, :transaction_key
    add_index :stripe_events, :created_at_unix

    add_index :stripe_objects, [:object_type, :object_id],
              unique: true, name: "uniq_object_snapshot"
  end
end
