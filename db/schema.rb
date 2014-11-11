# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20141018212156) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "connect_github_user_statuses", force: true do |t|
    t.integer  "user_id"
    t.integer  "github_user_id"
    t.string   "oauth_code"
    t.string   "status"
    t.string   "step"
    t.text     "error_message"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "delayed_jobs", force: true do |t|
    t.integer  "priority",   default: 0, null: false
    t.integer  "attempts",   default: 0, null: false
    t.text     "handler",                null: false
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], name: "delayed_jobs_priority", using: :btree

  create_table "github_emails", force: true do |t|
    t.integer  "github_user_id",             null: false
    t.string   "address",        limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "github_emails", ["github_user_id"], name: "index_github_emails_on_github_user_id", using: :btree

  create_table "github_teams", force: true do |t|
    t.string   "slug",         limit: 255
    t.string   "organization", limit: 255
    t.string   "name",         limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "github_user_disabled_teams", id: false, force: true do |t|
    t.integer "github_user_id"
    t.integer "github_team_id"
  end

  create_table "github_user_teams", id: false, force: true do |t|
    t.integer "github_user_id"
    t.integer "github_team_id"
  end

  create_table "github_users", force: true do |t|
    t.integer  "user_id"
    t.string   "login",           limit: 255,                     null: false
    t.boolean  "mfa"
    t.string   "encrypted_token", limit: 255
    t.datetime "last_sync_at"
    t.string   "sync_error",      limit: 255
    t.datetime "sync_error_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "state",           limit: 255, default: "unknown", null: false
    t.string   "avatar_url",      limit: 255
    t.string   "html_url",        limit: 255
  end

  add_index "github_users", ["login"], name: "index_github_users_on_login", unique: true, using: :btree
  add_index "github_users", ["user_id"], name: "index_github_users_on_user_id", using: :btree

  create_table "settings", force: true do |t|
    t.string   "key",        limit: 255
    t.text     "value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "settings", ["key"], name: "index_settings_on_key", unique: true, using: :btree

  create_table "users", force: true do |t|
    t.string   "username",             limit: 255, default: "", null: false
    t.string   "name",                 limit: 255
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                    default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip",   limit: 255
    t.string   "last_sign_in_ip",      limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "last_ldap_sync"
    t.integer  "ldap_account_control"
    t.string   "ldap_sync_error",      limit: 255
    t.datetime "ldap_sync_error_at"
    t.string   "email",                limit: 255
    t.boolean  "admin"
    t.string   "remember_token"
  end

  add_index "users", ["username"], name: "index_users_on_username", unique: true, using: :btree

end
