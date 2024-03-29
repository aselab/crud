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

ActiveRecord::Schema.define(version: 2018_05_02_140604) do

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.integer "record_id", null: false
    t.integer "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "ar_groups", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "ar_misc_belongings", force: :cascade do |t|
    t.integer "misc_id"
    t.string "name"
    t.index ["misc_id"], name: "index_ar_misc_belongings_on_misc_id"
  end

  create_table "ar_misc_habtms", force: :cascade do |t|
    t.string "name"
  end

  create_table "ar_misc_habtms_miscs", id: false, force: :cascade do |t|
    t.integer "misc_id"
    t.integer "misc_habtm_id"
    t.index ["misc_habtm_id"], name: "index_ar_misc_habtms_miscs_on_misc_habtm_id"
    t.index ["misc_id"], name: "index_ar_misc_habtms_miscs_on_misc_id"
  end

  create_table "ar_misc_throughs", force: :cascade do |t|
    t.integer "misc_belonging_id"
    t.string "name"
    t.index ["misc_belonging_id"], name: "index_ar_misc_throughs_on_misc_belonging_id"
  end

  create_table "ar_miscs", force: :cascade do |t|
    t.boolean "boolean"
    t.string "string"
    t.integer "integer"
    t.float "float"
    t.datetime "datetime"
    t.date "date"
    t.time "time"
    t.string "enumerized"
    t.decimal "decimal"
  end

  create_table "ar_permissions", force: :cascade do |t|
    t.string "permissible_type", null: false
    t.integer "permissible_id", null: false
    t.integer "user_id", null: false
    t.integer "flags", null: false
    t.index ["permissible_type", "permissible_id"], name: "index_ar_permissions_on_permissible_type_and_permissible_id"
    t.index ["user_id"], name: "index_ar_permissions_on_user_id"
  end

  create_table "ar_users", force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.string "email"
    t.date "birth_date"
    t.boolean "is_admin", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end
