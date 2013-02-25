class AddShippingSurchangeToPreference < ActiveRecord::Migration
  def change
    add_column :preference, :surchange_amount, :decimal 
  end
end
