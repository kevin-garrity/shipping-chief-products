module Carriers
  module Ridgewood
    class RidgewoodPreference < ActiveRecord::Base
      
      attr_accessible :domestic_regular_flat_rate, :domestic_express_flat_rate, :international_flat_rate
      
      attr_accessible :international_flat_rate_canada
      
      class UnknownShopError < StandardError; end
   
      self.table_name = 'ridgewood_preference'
   
      def self.find_by_shop(shop)
        preference = RidgewoodPreference.arel_table
    
        domain = shop.domain || ""
        myshopify_domain = shop.myshopify_domain || ""
    
        RidgewoodPreference.where(
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