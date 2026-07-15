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

ActiveRecord::Schema[8.1].define(version: 2026_07_15_094300) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "customer_sites", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "address_line_1", null: false
    t.string "address_line_2"
    t.string "city", null: false
    t.datetime "created_at", null: false
    t.uuid "created_by_id", null: false
    t.uuid "customer_id", null: false
    t.string "name", null: false
    t.string "postal_code", null: false
    t.string "site_status", null: false
    t.string "state", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_customer_sites_on_created_by_id"
    t.index ["customer_id"], name: "index_customer_sites_on_customer_id"
    t.index ["site_status"], name: "index_customer_sites_on_site_status"
  end

  create_table "customers", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "account_status", null: false
    t.datetime "created_at", null: false
    t.uuid "created_by_id", null: false
    t.string "industry"
    t.string "name", null: false
    t.integer "quote_approval_threshold_cents", default: 50000, null: false
    t.datetime "updated_at", null: false
    t.index ["account_status"], name: "index_customers_on_account_status"
    t.index ["created_by_id"], name: "index_customers_on_created_by_id"
  end

  create_table "permissions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "action", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.string "resource", null: false
    t.datetime "updated_at", null: false
    t.index ["resource", "action"], name: "index_permissions_on_resource_and_action", unique: true
  end

  create_table "role_permissions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "permission_id", null: false
    t.uuid "role_id", null: false
    t.datetime "updated_at", null: false
    t.index ["permission_id"], name: "index_role_permissions_on_permission_id"
    t.index ["role_id", "permission_id"], name: "index_role_permissions_on_role_id_and_permission_id", unique: true
    t.index ["role_id"], name: "index_role_permissions_on_role_id"
  end

  create_table "roles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "key", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_roles_on_key", unique: true
  end

  create_table "service_providers", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "created_by_id", null: false
    t.string "name", null: false
    t.string "provider_type", null: false
    t.string "status", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_service_providers_on_created_by_id"
    t.index ["provider_type"], name: "index_service_providers_on_provider_type"
    t.index ["status"], name: "index_service_providers_on_status"
  end

  create_table "service_request_costs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "amount_cents", null: false
    t.string "category", null: false
    t.datetime "created_at", null: false
    t.string "currency", default: "USD", null: false
    t.text "description"
    t.date "incurred_on", null: false
    t.uuid "recorded_by_id", null: false
    t.uuid "service_request_id", null: false
    t.datetime "updated_at", null: false
    t.index ["category"], name: "index_service_request_costs_on_category"
    t.index ["incurred_on"], name: "index_service_request_costs_on_incurred_on"
    t.index ["recorded_by_id"], name: "index_service_request_costs_on_recorded_by_id"
    t.index ["service_request_id", "incurred_on"], name: "idx_on_service_request_id_incurred_on_94c9d7d212"
    t.index ["service_request_id"], name: "index_service_request_costs_on_service_request_id"
  end

  create_table "service_request_quotes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "amended_at"
    t.uuid "amended_by_id"
    t.text "amendment_reason"
    t.integer "amount_cents", null: false
    t.text "approval_notes"
    t.boolean "approval_required", default: false, null: false
    t.datetime "approved_at"
    t.uuid "approved_by_id"
    t.datetime "created_at", null: false
    t.uuid "created_by_id", null: false
    t.string "currency", default: "USD", null: false
    t.text "description", null: false
    t.integer "original_amount_cents"
    t.datetime "rejected_at"
    t.uuid "rejected_by_id"
    t.uuid "service_request_id", null: false
    t.string "status", default: "draft", null: false
    t.datetime "submitted_at"
    t.datetime "updated_at", null: false
    t.index ["amended_by_id"], name: "index_service_request_quotes_on_amended_by_id"
    t.index ["approval_required"], name: "index_service_request_quotes_on_approval_required"
    t.index ["approved_by_id"], name: "index_service_request_quotes_on_approved_by_id"
    t.index ["created_by_id"], name: "index_service_request_quotes_on_created_by_id"
    t.index ["rejected_by_id"], name: "index_service_request_quotes_on_rejected_by_id"
    t.index ["service_request_id"], name: "index_service_request_quotes_on_service_request_id", unique: true
    t.index ["status"], name: "index_service_request_quotes_on_status"
  end

  create_table "service_requests", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "assigned_at"
    t.uuid "assigned_dispatcher_id"
    t.datetime "canceled_at"
    t.datetime "completion_verified_at"
    t.uuid "completion_verified_by_id"
    t.datetime "created_at", null: false
    t.uuid "created_by_id", null: false
    t.uuid "customer_site_id", null: false
    t.text "description"
    t.text "follow_up_notes"
    t.string "priority", null: false
    t.integer "provider_completion_seconds"
    t.datetime "provider_responded_at"
    t.integer "provider_response_seconds"
    t.text "provider_response_summary"
    t.datetime "provider_work_completed_at"
    t.datetime "reported_at", null: false
    t.integer "resolution_seconds"
    t.datetime "resolved_at"
    t.datetime "scheduled_at"
    t.uuid "service_provider_id", null: false
    t.string "status", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.integer "verification_lag_seconds"
    t.index ["assigned_at"], name: "index_service_requests_on_assigned_at"
    t.index ["assigned_dispatcher_id"], name: "index_service_requests_on_assigned_dispatcher_id"
    t.index ["completion_verified_by_id"], name: "index_service_requests_on_completion_verified_by_id"
    t.index ["created_by_id"], name: "index_service_requests_on_created_by_id"
    t.index ["customer_site_id"], name: "index_service_requests_on_customer_site_id"
    t.index ["priority"], name: "index_service_requests_on_priority"
    t.index ["provider_completion_seconds"], name: "index_service_requests_on_provider_completion_seconds"
    t.index ["provider_responded_at"], name: "index_service_requests_on_provider_responded_at"
    t.index ["provider_response_seconds"], name: "index_service_requests_on_provider_response_seconds"
    t.index ["reported_at"], name: "index_service_requests_on_reported_at"
    t.index ["resolved_at"], name: "index_service_requests_on_resolved_at"
    t.index ["service_provider_id"], name: "index_service_requests_on_service_provider_id"
    t.index ["status"], name: "index_service_requests_on_status"
  end

  create_table "user_role_assignments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "resource_id"
    t.string "resource_type"
    t.uuid "role_id", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["resource_type", "resource_id"], name: "index_user_role_assignments_on_resource"
    t.index ["role_id"], name: "index_user_role_assignments_on_role_id"
    t.index ["user_id", "role_id", "resource_type", "resource_id"], name: "index_user_role_assignments_on_scoped_role", unique: true, where: "((resource_type IS NOT NULL) AND (resource_id IS NOT NULL))"
    t.index ["user_id", "role_id"], name: "index_user_role_assignments_on_global_role", unique: true, where: "((resource_type IS NULL) AND (resource_id IS NULL))"
    t.index ["user_id"], name: "index_user_role_assignments_on_user_id"
    t.check_constraint "resource_type IS NULL AND resource_id IS NULL OR resource_type IS NOT NULL AND resource_id IS NOT NULL", name: "user_role_assignments_resource_presence"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "name", null: false
    t.string "role", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["role"], name: "index_users_on_role"
  end

  add_foreign_key "customer_sites", "customers"
  add_foreign_key "customer_sites", "users", column: "created_by_id"
  add_foreign_key "customers", "users", column: "created_by_id"
  add_foreign_key "role_permissions", "permissions"
  add_foreign_key "role_permissions", "roles"
  add_foreign_key "service_providers", "users", column: "created_by_id"
  add_foreign_key "service_request_costs", "service_requests"
  add_foreign_key "service_request_costs", "users", column: "recorded_by_id"
  add_foreign_key "service_request_quotes", "service_requests"
  add_foreign_key "service_request_quotes", "users", column: "amended_by_id"
  add_foreign_key "service_request_quotes", "users", column: "approved_by_id"
  add_foreign_key "service_request_quotes", "users", column: "created_by_id"
  add_foreign_key "service_request_quotes", "users", column: "rejected_by_id"
  add_foreign_key "service_requests", "customer_sites"
  add_foreign_key "service_requests", "service_providers"
  add_foreign_key "service_requests", "users", column: "assigned_dispatcher_id"
  add_foreign_key "service_requests", "users", column: "completion_verified_by_id"
  add_foreign_key "service_requests", "users", column: "created_by_id"
  add_foreign_key "user_role_assignments", "roles"
  add_foreign_key "user_role_assignments", "users"
end
