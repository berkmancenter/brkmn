# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2020_07_09_185052) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "urls", id: :serial, force: :cascade do |t|
    t.string "shortened", limit: 255
    t.string "to", limit: 10240, null: false
    t.integer "user_id"
    t.boolean "auto", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "clicks", default: 0
    t.index ["auto"], name: "index_urls_on_auto"
    t.index ["clicks"], name: "index_urls_on_clicks"
    t.index ["shortened"], name: "index_urls_on_shortened"
    t.index ["to"], name: "index_urls_on_to"
    t.index ["user_id"], name: "index_urls_on_user_id"
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "username", limit: 100, null: false
    t.string "email", limit: 100
    t.boolean "superadmin", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email"
    t.index ["superadmin"], name: "index_users_on_superadmin"
    t.index ["username"], name: "index_users_on_username"
  end

end
