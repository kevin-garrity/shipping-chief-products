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

ActiveRecord::Schema.define(:version => 20140311185115) do

  create_table "cached_products", :force => true do |t|
    t.integer "product_id"
    t.integer "shop_id"
    t.string  "sku"
    t.integer "height"
    t.integer "width"
    t.integer "length"
  end

  create_table "chief_products_preference", :force => true do |t|
    t.string  "shop_url"
    t.boolean "offer_australia_post"
    t.boolean "offer_e_go"
    t.boolean "e_go_booking_type"
  end

  create_table "postal_code_range_preference", :force => true do |t|
    t.string "shop_url"
  end

  create_table "postal_code_ranges", :force => true do |t|
    t.string  "postal_code_range_preference_id"
    t.integer "postal_code_from"
    t.integer "postal_code_to"
    t.decimal "shipping_rate"
  end

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
    t.string  "carrier"
    t.boolean "free_shipping_option"
    t.string  "free_shipping_description"
    t.boolean "offers_flat_rate"
    t.decimal "under_weight"
    t.decimal "flat_rate"
    t.boolean "free_shipping_by_collection"
  end

  create_table "ridgewood_preference", :force => true do |t|
    t.string  "shop_url"
    t.decimal "domestic_regular_flat_rate"
    t.decimal "domestic_express_flat_rate"
    t.decimal "international_flat_rate"
    t.decimal "international_flat_rate_canada"
    t.decimal "height_2"
    t.decimal "width_2"
    t.decimal "length_2"
    t.decimal "height_3"
    t.decimal "width_3"
    t.decimal "length_3"
  end

  create_table "shops", :force => true do |t|
    t.string   "myshopify_domain"
    t.string   "token"
    t.boolean  "active_subscriber"
    t.datetime "signup_date"
    t.datetime "created_at",        :null => false
    t.datetime "updated_at",        :null => false
    t.string   "charge_id"
    t.string   "status"
    t.boolean  "theme_modified"
    t.integer  "version"
    t.string   "domain"
  end

end
