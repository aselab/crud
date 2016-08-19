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

ActiveRecord::Schema.define(version: 20160819113032) do

  create_table "companies", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "groups", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "permissions", force: :cascade do |t|
    t.string  "permissible_type", null: false
    t.integer "permissible_id",   null: false
    t.integer "user_id",          null: false
    t.integer "flags",            null: false
    t.index ["permissible_id", "permissible_type"], name: "index_permissible_keys"
    t.index ["user_id"], name: "index_permissions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string   "name"
    t.date     "birth_date"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "number"
    t.integer  "company_id"
  end

end
