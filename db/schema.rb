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

ActiveRecord::Schema[7.2].define(version: 2026_09_17_000000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "sessions", force: :cascade do |t|
    t.string "session_id", null: false
    t.text "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["session_id"], name: "index_sessions_on_session_id", unique: true
    t.index ["updated_at"], name: "index_sessions_on_updated_at"
  end

  create_table "url_access_requests", force: :cascade do |t|
    t.bigint "url_id", null: false
    t.bigint "user_id", null: false
    t.integer "status", default: 0, null: false
    t.bigint "resolved_by_id"
    t.datetime "resolved_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["resolved_by_id"], name: "index_url_access_requests_on_resolved_by_id"
    t.index ["url_id", "user_id"], name: "index_url_access_requests_on_url_id_and_user_id", unique: true
    t.index ["url_id"], name: "index_url_access_requests_on_url_id"
    t.index ["user_id"], name: "index_url_access_requests_on_user_id"
    t.check_constraint "status = ANY (ARRAY[0, 1, 2])", name: "url_access_requests_status"
  end

  create_table "url_collaborators", force: :cascade do |t|
    t.bigint "url_id", null: false
    t.bigint "user_id", null: false
    t.bigint "granted_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["granted_by_id"], name: "index_url_collaborators_on_granted_by_id"
    t.index ["url_id", "user_id"], name: "index_url_collaborators_on_url_id_and_user_id", unique: true
    t.index ["url_id"], name: "index_url_collaborators_on_url_id"
    t.index ["user_id"], name: "index_url_collaborators_on_user_id"
  end

  create_table "urls", id: :serial, force: :cascade do |t|
    t.string "shortened", limit: 255
    t.string "to", limit: 10240, null: false
    t.integer "user_id"
    t.boolean "auto", default: true
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "clicks", default: 0
    t.bigint "last_edited_by_id"
    t.datetime "last_edited_at"
    t.index ["auto"], name: "index_urls_on_auto"
    t.index ["clicks"], name: "index_urls_on_clicks"
    t.index ["last_edited_by_id"], name: "index_urls_on_last_edited_by_id"
    t.index ["shortened"], name: "index_urls_on_shortened"
    t.index ["to"], name: "index_urls_on_to"
    t.index ["user_id"], name: "index_urls_on_user_id"
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "username", limit: 100, null: false
    t.string "email", limit: 100
    t.boolean "superadmin", default: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at", precision: nil
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.index ["email"], name: "index_users_on_email"
    t.index ["superadmin"], name: "index_users_on_superadmin"
    t.index ["username"], name: "index_users_on_username"
  end

  add_foreign_key "url_access_requests", "urls"
  add_foreign_key "url_access_requests", "users"
  add_foreign_key "url_access_requests", "users", column: "resolved_by_id"
  add_foreign_key "url_collaborators", "urls"
  add_foreign_key "url_collaborators", "users"
  add_foreign_key "url_collaborators", "users", column: "granted_by_id"
  add_foreign_key "urls", "users", column: "last_edited_by_id"
end
