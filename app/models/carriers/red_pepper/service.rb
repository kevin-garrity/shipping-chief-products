module Carriers
  module RedPepper
    class Service < ::Carriers::Service
      

      def fetch_rates
        Rails.logger.info("#{self.class.name}#fetch_rates")
        withShopify do
          return [] unless contains_food?

          rates = calculator.get_rates(origin, destination, packages)
          Rails.logger.info("rates: #{rates.inspect}")

          rates = overnight_only(rates)
          addCoolerCharge(rates)
        end
      end

      def overnight_only(rates)
        rates.select { |rate| rate["service_name"].downcase.include?('overnight') }
      end

      def calculator
        @calculator ||= FedexRate.new
      end      

      def addCoolerCharge(rates)
        rates.each do|rate|
          rate['total_price'] = rate['total_price'] .to_i + 2700 
          rate['service_name'] << " (includes $27 refundable deposit for the cooler)"
        end
        rates
        
      end

      def packages
        weight = items.inject(0) { |w, item| w += item[:grams].to_i * item[:quantity].to_i }
        [Package.new(weight, [])]
      end

      def contains_food?
        items.any? { |item| food_item?( item ) }
      end

      def food_item?(item)
        food_items.include?( item[:sku] )
      end

      def food_items
        Rails.logger.debug(shop.token)
        @food_items ||= begin
          products = ShopifyAPI::Product.find(:all, 
            params: {collection_id: food_collection.id, limit: 250, fields: 'id'})
          skus = []
          products.each do |product|
            variant = ShopifyAPI::Variant.find(:all,  params:{limit: 250, fields: 'sku', product_id: product.id})
            skus += variant.map(&:sku)
          end
          skus
        end
      end

      def food_collection
        @food_collection ||= ShopifyAPI::CustomCollection.find(:first, params: {handle: 'food'})
      end

    end    
  end
end
