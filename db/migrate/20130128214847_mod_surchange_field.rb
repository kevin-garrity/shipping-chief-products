class ModSurchangeField < ActiveRecord::Migration
  def up
    change_column :preference, :surchange_percentage, :float 
  end

  def down
    change_column :preference, :surchange_percentage, :string 
  end
end
