class ChangeDimension < ActiveRecord::Migration
  def up
    change_column :cached_products, :height, :decimal
    change_column :cached_products, :width, :decimal    
    change_column :cached_products, :length, :decimal    
  end

  def down
  end
end
