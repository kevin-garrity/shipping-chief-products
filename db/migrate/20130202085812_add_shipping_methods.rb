class AddShippingMethods < ActiveRecord::Migration
  def change
    add_column :preference, :shipping_methods_allowed, :text
  end
end
