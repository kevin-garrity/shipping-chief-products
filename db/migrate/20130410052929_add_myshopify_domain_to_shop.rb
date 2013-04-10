class AddMyshopifyDomainToShop < ActiveRecord::Migration
  def change
    add_column :shops, :domain, :string
    rename_column :shops, :url, :myshopify_domain
    Shop.all.each{|shop| shop.update_attribute(:domain, shop.myshopify_domain)}
  end
end
