class AddCarrierToPreference < ActiveRecord::Migration
  def change
    add_column :preference, :carrier, :string
    
    ActiveRecord::Base.connection.execute("UPDATE preference SET carrier='AusPost'")
  end
end
