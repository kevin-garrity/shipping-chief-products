module Carriers
  module ChiefProducts
    class ChiefProductsPreference < ActiveRecord::Base
      
      attr_accessible :offer_australia_post, :offer_e_go, :ego_depot_option, :aus_post_explanation, :ego_explanation

      
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