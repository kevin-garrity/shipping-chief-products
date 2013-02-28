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

ActiveRecord::Schema.define(:version => 20130228205930) do

  create_table "preference", :force => true do |t|
    t.string  "shop_url"
    t.string  "origin_postal_code"
    t.string  "default_weight"
    t.decimal "height",                       :precision => 10, :scale => 2
    t.decimal "width",                        :precision => 10, :scale => 2
    t.decimal "length",                       :precision => 10, :scale => 2
    t.float   "surcharge_percentage"
    t.integer "items_per_box"
    t.decimal "default_charge",               :precision => 10, :scale => 2
    t.text    "shipping_methods_allowed_int"
    t.decimal "container_weight",             :precision => 10, :scale => 2
    t.text    "shipping_methods_allowed_dom"
    t.integer "default_box_size"
    t.text    "shipping_methods_desc_int"
    t.text    "shipping_methods_desc_dom"
    t.decimal "surcharge_amount"
    t.boolean "hide_welcome_note"
  end

  create_table "shops", :force => true do |t|
    t.string   "url"
    t.string   "token"
    t.boolean  "active_subscriber"
    t.datetime "signup_date"
    t.datetime "created_at",        :null => false
    t.datetime "updated_at",        :null => false
    t.string   "charge_id"
    t.string   "status"
    t.boolean  "theme_modified"
  end

end
