class AddChargeIdtoShop < ActiveRecord::Migration
  def up
    add_column :shops, :charge_id, :string
    add_column :shops, :status, :string
    
  end

  def down
    remove_column :shops, :charge_id
    remove_column :shops, :status
  end
end
