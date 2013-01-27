class AddDimensionToPreference < ActiveRecord::Migration
  def change
      add_column :preference, :height, :decimal
      add_column :preference, :width, :decimal
      add_column :preference, :depth, :decimal      
    end
end
