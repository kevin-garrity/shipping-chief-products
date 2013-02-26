class FixSpellingSurchange < ActiveRecord::Migration
  def up
    rename_column :preference, :surchange_percentage, :surcharge_percentage   
    rename_column :preference, :surchange_amount, :surcharge_amount   
  end

  def down
  end
end
