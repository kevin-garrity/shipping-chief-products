class AddVersionToShop < ActiveRecord::Migration
  def change
     add_column :shops, :version, :integer
     
     Shop.all.each do |shop|
         shop.update_attributes!(:version => '1')
     end
   end
end
