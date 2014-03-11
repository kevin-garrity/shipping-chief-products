class AddRidgeWoodDimensions < ActiveRecord::Migration
  def up
    add_column :ridgewood_preference, :height_2, :decimal
    add_column :ridgewood_preference, :width_2, :decimal
    add_column :ridgewood_preference, :length_2, :decimal
    
    add_column :ridgewood_preference, :height_3, :decimal
    add_column :ridgewood_preference, :width_3, :decimal
    add_column :ridgewood_preference, :length_3, :decimal
  end

  def down
    remove_column :ridgewood_preference, :height_2
    remove_column :ridgewood_preference, :width_2
    remove_column :ridgewood_preference, :length_2
    
    remove_column :ridgewood_preference, :height_3
    remove_column :ridgewood_preference, :width_3
    remove_column :ridgewood_preference, :length_3
  end
end
