class AddEgoDepotOptionToChiefPreference < ActiveRecord::Migration
  def change
    add_column :chief_products_preference, :ego_depot_option, :string
  end
end
