class AddLongShippingMethodDesc < ActiveRecord::Migration
  def up
    add_column :preference, :shipping_methods_long_desc_int, :text
    add_column :preference, :shipping_methods_long_desc_dom, :text
  end

  def down
    remove_column :preference, :shipping_methods_long_desc_int
    remove_column :preference, :shipping_methods_long_desc_dom
  end
end
