class AddFieldToSetting < ActiveRecord::Migration
  def change
    add_column :preference, :items_per_box, :integer    
  end
end
