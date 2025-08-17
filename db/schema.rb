# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_08_16_233054) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "app_settings", force: :cascade do |t|
    t.bigint "tenant_id", null: false
    t.boolean "fetch_fees"
    t.string "stripe_api_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tenant_id"], name: "index_app_settings_on_tenant_id"
  end

  create_table "domains", force: :cascade do |t|
    t.string "host"
    t.bigint "tenant_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["host"], name: "index_domains_on_host"
    t.index ["tenant_id"], name: "index_domains_on_tenant_id"
  end

  create_table "stripe_events", force: :cascade do |t|
    t.string "stripe_id"
    t.string "type_name"
    t.string "api_version"
    t.string "account"
    t.boolean "livemode"
    t.integer "created_at_unix"
    t.string "source"
    t.string "transaction_key"
    t.jsonb "payload"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "tenant_id", null: false
    t.index ["created_at_unix"], name: "index_stripe_events_on_created_at_unix"
    t.index ["stripe_id"], name: "index_stripe_events_on_stripe_id", unique: true
    t.index ["tenant_id", "transaction_key", "created_at_unix"], name: "idx_events_tenant_key_time"
    t.index ["tenant_id"], name: "index_stripe_events_on_tenant_id"
    t.index ["transaction_key"], name: "index_stripe_events_on_transaction_key"
  end

  create_table "stripe_objects", force: :cascade do |t|
    t.string "object_type"
    t.string "object_id"
    t.string "account"
    t.jsonb "current"
    t.string "last_event_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "tenant_id", null: false
    t.index ["tenant_id", "object_type", "object_id"], name: "idx_objects_tenant_type_id", unique: true
    t.index ["tenant_id", "object_type", "object_id"], name: "uniq_object_snapshot", unique: true
    t.index ["tenant_id"], name: "index_stripe_objects_on_tenant_id"
  end

  create_table "stripe_relations", force: :cascade do |t|
    t.string "from_type"
    t.string "from_id"
    t.string "to_type"
    t.string "to_id"
    t.string "relation"
    t.string "account"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "tenant_id", null: false
    t.index ["tenant_id", "from_type", "from_id", "to_type", "to_id", "relation", "account"], name: "uniq_relations_graph", unique: true
    t.index ["tenant_id", "from_type", "from_id", "to_type", "to_id", "relation"], name: "idx_relations_tenant_multi"
    t.index ["tenant_id"], name: "index_stripe_relations_on_tenant_id"
  end

  create_table "tenants", force: :cascade do |t|
    t.string "name"
    t.string "primary_domain"
    t.string "webhook_signing_secret"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["primary_domain"], name: "index_tenants_on_primary_domain"
  end

  create_table "transaction_summaries", force: :cascade do |t|
    t.string "transaction_key", null: false
    t.string "last_type"
    t.integer "last_event_at_unix"
    t.integer "amount_integer"
    t.string "currency"
    t.string "status"
    t.string "latest_pi"
    t.string "latest_charge"
    t.string "email"
    t.boolean "livemode"
    t.string "account"
    t.integer "events_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "last4"
    t.string "order_id"
    t.string "customer_id"
    t.bigint "tenant_id", null: false
    t.index ["tenant_id", "last_event_at_unix"], name: "idx_tx_summaries_tenant_time"
    t.index ["tenant_id"], name: "index_transaction_summaries_on_tenant_id"
    t.index ["transaction_key"], name: "index_transaction_summaries_on_transaction_key", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.bigint "tenant_id", null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.string "role", default: "owner", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tenant_id", "email"], name: "index_users_on_tenant_id_and_email", unique: true
    t.index ["tenant_id"], name: "index_users_on_tenant_id"
  end

  add_foreign_key "app_settings", "tenants"
  add_foreign_key "domains", "tenants"
  add_foreign_key "stripe_events", "tenants"
  add_foreign_key "stripe_objects", "tenants"
  add_foreign_key "stripe_relations", "tenants"
  add_foreign_key "transaction_summaries", "tenants"
  add_foreign_key "users", "tenants"
end
