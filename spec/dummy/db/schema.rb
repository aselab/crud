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

ActiveRecord::Schema.define(version: 20161005102104) do

  create_table "ar_groups", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "ar_misc_belongings", force: :cascade do |t|
    t.integer "misc_id"
    t.string  "name"
    t.index ["misc_id"], name: "index_ar_misc_belongings_on_misc_id"
  end

  create_table "ar_miscs", force: :cascade do |t|
    t.boolean  "boolean"
    t.string   "string"
    t.integer  "integer"
    t.float    "float"
    t.datetime "datetime"
    t.date     "date"
    t.time     "time"
    t.string   "enumerized"
  end

  create_table "ar_permissions", force: :cascade do |t|
    t.string  "permissible_type", null: false
    t.integer "permissible_id",   null: false
    t.integer "user_id",          null: false
    t.integer "flags",            null: false
    t.index ["permissible_type", "permissible_id"], name: "index_ar_permissions_on_permissible_type_and_permissible_id"
    t.index ["user_id"], name: "index_ar_permissions_on_user_id"
  end

  create_table "ar_users", force: :cascade do |t|
    t.string   "first_name"
    t.string   "last_name"
    t.string   "email"
    t.date     "birth_date"
    t.boolean  "is_admin",   default: false
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
  end

end
