class AddRidgewoodPreference < ActiveRecord::Migration
  def up
     create_table :ridgewood_preference do |t|
        t.string  :shop_url
        t.decimal :domestic_regular_flat_rate
        t.decimal :domestic_express_flat_rate
        t.decimal :international_flat_rate    
      end
  end

  def down
    drop_table :ridgewood_preference    
  end
end
