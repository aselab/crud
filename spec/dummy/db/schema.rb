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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20130820023500) do

  create_table "events", :force => true do |t|
    t.string   "name"
    t.integer  "person_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "people", :force => true do |t|
    t.string   "name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.integer  "position"
  end

  create_table "permissions", :force => true do |t|
    t.integer "permissible_id",   :null => false
    t.string  "permissible_type", :null => false
    t.integer "user_id",          :null => false
    t.integer "flags",            :null => false
  end

  add_index "permissions", ["permissible_id", "permissible_type"], :name => "index_permissions_on_permissible_id_and_permissible_type"
  add_index "permissions", ["user_id"], :name => "index_permissions_on_user_id"

  create_table "principals", :force => true do |t|
    t.string   "type"
    t.string   "name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

end
