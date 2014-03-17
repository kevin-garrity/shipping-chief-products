class AddChiefProductsPreference < ActiveRecord::Migration
  def up
    create_table :chief_products_preference do |t|
        t.string  :shop_url
        t.boolean :offer_australia_post
        t.boolean :offer_e_go
        t.boolean :e_go_booking_type        
    end
    
    create_table :cached_products do |t|
      t.integer :product_id
      t.integer :shop_id
      t.string :sku
      t.integer :height
      t.integer :width
      t.integer :length
      t.string :product_name
    end
  end

  def down
    drop_table :chief_products_preference
    drop_table :products
  end
end
