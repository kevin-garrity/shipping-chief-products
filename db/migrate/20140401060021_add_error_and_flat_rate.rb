class AddErrorAndFlatRate < ActiveRecord::Migration
  def change
    add_column :chief_products_preference, :rate_lookup_error, :string
        
  end

end
