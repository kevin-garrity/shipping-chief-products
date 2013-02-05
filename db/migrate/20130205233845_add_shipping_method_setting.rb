class AddShippingMethodSetting < ActiveRecord::Migration
  def change
    rename_column :preference, :shipping_methods_allowed, :shipping_methods_allowed_int
    add_column :preference, :shipping_methods_allowed_dom, :text
   end
end
