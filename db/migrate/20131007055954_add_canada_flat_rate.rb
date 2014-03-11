class AddCanadaFlatRate < ActiveRecord::Migration
  def up
    add_column :ridgewood_preference, :international_flat_rate_canada, :decimal
    
  end

  def down
    remove_column :ridgewood_preference, :international_flat_rate_canada
    
  end
end
