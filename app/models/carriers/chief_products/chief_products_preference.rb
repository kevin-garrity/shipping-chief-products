module Carriers
  module ChiefProducts
    class ChiefProductsPreference < ActiveRecord::Base
      
      attr_accessible :product_dimension_metafields_key, :product_dimension_metafields_namespace, :offer_australia_post, :offer_e_go

      
      class UnknownShopError < StandardError; end
   
      self.table_name = 'chief_products_preference'
   
      def self.find_by_shop(shop)
        preference = ChiefProductsPreference.arel_table
    
        domain = shop.domain || ""
        myshopify_domain = shop.myshopify_domain || ""
    
        ChiefProductsPreference.where(
          preference[:shop_url].eq( domain ).
          or(
          preference[:shop_url].eq( myshopify_domain ))
        ).first
      end
      
      def in_cents(field_name)
        (self.send(field_name) * 100).to_i
      end
    end
  end
end