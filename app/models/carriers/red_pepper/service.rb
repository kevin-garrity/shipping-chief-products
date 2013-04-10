module Carriers
  module RedPepper
    class Service < ::Carriers::Service
      

      def fetch_rates
        Rails.logger.info("#{self.class.name}#fetch_rates")
        withShopify do
          
          only_giftcards = true
          #only giftcards
          
          collection_sku_prefixs = Array.new

          items.each do |item|
            sku = item[:sku]
            if (!sku.start_with?("GC-")) #found giftcard
              only_giftcards = false
            end
            # get all the collections by looking at pattern XXX-
            match = sku.match('[^-]*-')
            unless match.nil?  
              if (!collection_sku_prefixs.include?(match[0]))
                collection_sku_prefixs << match[0]
              end
            end
          end
          
          # flat shipping if only giftcards
          return [] if (only_giftcards) 
          
          
          rates_array = Array.new
          
          # shipping rate is calculated at a per collection level.
          # item in the food collection is shipped individually
          # items in other collections can be shipped together
          collection_sku_prefixs.each do |coll_prefix|
            collect_items = items.collect {|item| item[:sku].starts_with?(coll_prefix)}
            #all items are shipped seperately
            if (coll_prefix == 'FOOD-')
               collect_items.each do |item|
                packages = Array.new
                quan = item[:quantity].to_i
                weight = item[:grams].to_i * quan

                packages << Package.new(weight, [])
                  
                rates = calculator.get_rates(origin, destination, packages)
                Rails.logger.info("rates: #{rates.inspect}")

                rates = overnight_only(rates)
                addCoolerCharge(rates)       
                rates_array << rates
                 
              end # end each collect_items
            else  # if not food items
              #ignore giftcards items as they can be shipped together with other items
              unless (coll_prefix == 'GC-')
                packages = Array.new
                weight = 0
                collect_items.each do |item|                 
                  quan = item[:quantity].to_i
                  weight = weight + item[:grams].to_i * quan
                end # end each
                packages << Package.new(weight, [])
                rates = calculator.get_rates(origin, destination, packages)
                rates_array << rates                
              end
            end 
           
          end # end each collection_sku_prefixs
          
          consolidate_rates(rates_array)          
          
        end # end with shopify
      end

      def consolidate_rates(rates_array)
        find_rates = Hash.new
        #go through all the rates and total them up
        rates_array.each do |rate|
          rate.each do |r|
            if (find_rates.has_key?(r["service_name"]))     
              Rails.logger.info('adding rate' + (r["total_price"].to_i + find_rates[r["service_name"]]["total_price"].to_i).to_s)
              find_rates[r["service_name"]] = { "service_name" =>r["service_name"], 
                                                "service_code"=>r["service_code"], 
                                                "total_price" => r["total_price"].to_i + find_rates[r["service_name"]]["total_price"].to_i, 
                                                "currency" => r["currency"] 
                                                }
            else          
              find_rates[r["service_name"]] = { "service_name" =>r["service_name"], 
                                                "service_code" =>r["service_code"], 
                                                "total_price" => r["total_price"].to_i, 
                                                "currency" => r["currency"]
                                              }                                            
            end
          end # end rate.each
        end # end rates_array.each
        find_rates.values
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
          rate['service_name'] =  rate['service_name'] + " (includes $27 refundable cooler deposit for each item)"          
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
