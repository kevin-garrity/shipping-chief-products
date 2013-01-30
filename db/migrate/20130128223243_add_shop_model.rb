class AddShopModel < ActiveRecord::Migration
  def up
    create_table :shops do |t|
      t.string :url
      t.string :token
      t.boolean :active_subscriber
      t.datetime :signup_date
      t.timestamps
    end
    add_index "shops", ["url"], :name => "index_shops_on_url"    
  end

  def down
    drop_table :shops
  end
end
