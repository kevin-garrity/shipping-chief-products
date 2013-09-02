class AddFreeShippingByCollection < ActiveRecord::Migration
  def up
     add_column :preference, :free_shipping_by_collection, :bool
  end

  def down
    remove_column :preference, :free_shipping_by_collection
  end
end
