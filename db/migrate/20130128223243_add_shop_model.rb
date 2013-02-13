class AddShopModel < ActiveRecord::Migration
  def up
    create_table :shops do |t|
      t.string :url
      t.string :token
      t.boolean :active_subscriber
      t.datetime :signup_date
      t.timestamps
    end
  end

  def down
    drop_table :shops
  end
end
