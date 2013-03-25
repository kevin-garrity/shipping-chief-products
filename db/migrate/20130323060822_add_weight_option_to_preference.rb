class AddWeightOptionToPreference < ActiveRecord::Migration
  def change
    add_column :preference, :offers_flat_rate, :bool
    add_column :preference, :under_weight, :decimal    
    add_column :preference, :flat_rate, :decimal
  end
end
