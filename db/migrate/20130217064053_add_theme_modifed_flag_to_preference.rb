class AddThemeModifedFlagToPreference < ActiveRecord::Migration
  def change
    add_column :shops, :theme_modified, :bool    
  end
end
