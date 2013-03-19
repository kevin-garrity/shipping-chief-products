class AddFreeShippingToPreference < ActiveRecord::Migration
  def change
    add_column :preference, :free_shipping_option, :bool
    add_column :preference, :free_shipping_description, :string
  end
end
