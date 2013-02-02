class RenameDepthForPreference < ActiveRecord::Migration
  def change
    rename_column :preference, :depth, :length    
  end
end
