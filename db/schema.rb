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

ActiveRecord::Schema.define(version: 2021_03_11_145806) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "connect_github_user_statuses", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "github_user_id"
    t.string "oauth_code"
    t.string "status"
    t.string "step"
    t.text "error_message"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "delayed_jobs", id: :serial, force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "github_emails", id: :serial, force: :cascade do |t|
    t.integer "github_user_id", null: false
    t.string "address"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["github_user_id"], name: "index_github_emails_on_github_user_id"
  end

  create_table "github_organization_memberships", id: :serial, force: :cascade do |t|
    t.integer "github_user_id", null: false
    t.string "organization", null: false
    t.string "role"
    t.string "state"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["github_user_id"], name: "index_github_organization_memberships_on_github_user_id"
  end

  create_table "github_teams", id: :serial, force: :cascade do |t|
    t.string "slug"
    t.string "organization"
    t.string "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "github_user_disabled_teams", id: false, force: :cascade do |t|
    t.integer "github_user_id"
    t.integer "github_team_id"
  end

  create_table "github_user_teams", id: false, force: :cascade do |t|
    t.integer "github_user_id"
    t.integer "github_team_id"
  end

  create_table "github_users", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.string "login", null: false
    t.boolean "mfa"
    t.string "encrypted_token"
    t.datetime "last_sync_at"
    t.string "sync_error"
    t.datetime "sync_error_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "state", default: "unknown", null: false
    t.string "avatar_url"
    t.string "html_url"
    t.index ["login"], name: "index_github_users_on_login", unique: true
    t.index ["user_id"], name: "index_github_users_on_user_id"
  end

  create_table "settings", id: :serial, force: :cascade do |t|
    t.string "key"
    t.text "value"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["key"], name: "index_settings_on_key", unique: true
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "username", default: "", null: false
    t.string "name"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "last_ldap_sync"
    t.integer "ldap_account_control"
    t.string "ldap_sync_error"
    t.datetime "ldap_sync_error_at"
    t.string "email"
    t.boolean "admin"
    t.string "remember_token"
    t.string "department"
    t.index ["username"], name: "index_users_on_username", unique: true
  end

end
