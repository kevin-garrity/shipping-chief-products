class ModSurchangeField < ActiveRecord::Migration
  def up
    remove_column :preference, :surchange_percentage
    add_column :preference, :surchange_percentage, :float 
  end

  def down
    change_column :preference, :surchange_percentage, :string 
  end
end
