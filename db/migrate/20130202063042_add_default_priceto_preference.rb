class AddDefaultPricetoPreference < ActiveRecord::Migration
  def change
    add_column :preference, :default_charge, :decimal
  end
end
