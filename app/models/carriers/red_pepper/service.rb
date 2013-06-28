module Carriers
  module RedPepper
    class Service < ::Carriers::Service
      

      def checkForFoodItems
        has_non_food_items = has_food_item = false
         items.each do |item|
          sku = item[:sku]
          if (sku.start_with?("FOOD-")) 
            has_food_item = true
          else
            has_non_food_items = true
          end
        end
        [has_non_food_items, has_food_item]
      end

      def fetch_rates
        Rails.logger.info("#{self.class.name}#fetch_rates aaaaargh")
        withShopify do
          
          has_non_food_items, has_food_item = checkForFoodItems
          #only giftcards
          
          collection_sku_prefixs = Array.new


            # get all the collections by looking at pattern XXX-
          items.each do |item|
            match = item[:sku].match('[^-]*-')
            unless match.nil?  
              if (!collection_sku_prefixs.include?(match[0]))
                collection_sku_prefixs << match[0]
              end
            end
          end
          
          weight = 0
          # if there is no food item, only need to query once
          if (has_non_food_items && !has_food_item)
            #make one query to fedex
            items.each do |item|
              quan = item[:quantity].to_i               
              weight = weight + item[:grams].to_i * quan
            end
            packages = Array.new
            
            packages << Package.new(weight, [])
            
            rates = calculator.get_rates(origin, destination, packages)
            return rates;
          end
          # flat shipping if only giftcards
#          return [] if (only_giftcards) 
          
          
          rates_array = Array.new
          total_cooler_charge = 0
          extra_charge = 0
          
          
          # shipping rate is calculated at a per collection level.
          # item in the food collection is shipped individually
          # items in other collections can be shipped together
          collection_sku_prefixs.each do |coll_prefix|
            collect_items = items.select {|item| item[:sku].starts_with?(coll_prefix)}
            #all items are shipped seperately
            if (coll_prefix == 'FOOD-')
               collect_items.each do |item|
                packages = Array.new
               
                quan = item[:quantity].to_i               
                weight = item[:grams].to_i

                packages << Package.new(weight, [])
                  
                rates = calculator.get_rates(origin, destination, packages)
                Rails.logger.info("rates: #{rates.inspect}")

                rates = overnight_only(rates)
                #each item is shipped seperately
                rates = multiple_charge(rates, quan) if quan > 1
 
                total_cooler_charge = total_cooler_charge + 2700 * quan
                rates_array << rates
                 
              end # end each collect_items
            else  # if not food items
              if (has_food_item && has_non_food_items)
                # giftcards items can be shipped together with other items                
                packages = Array.new
                weight = 0
                collect_items.each do |item|                 
                  extra_charge = extra_charge + 500 #assume all other itmems wil cost 5 dollar to ship
                end # end each                              
              end  
            end 
           
          end # end each collection_sku_prefixs
          
          rates = consolidate_rates(rates_array)          
          
          rates = addCoolerCharge(rates, total_cooler_charge) if total_cooler_charge > 0 
          rates = addExtraCharge(rates, extra_charge) if extra_charge > 0 
          
          Rails.logger.info('final rate is ' + rates.inspect)
          return rates
          
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

      def multiple_charge(rates, multiplier)
        rates.each do|rate|
          rate['total_price'] = rate['total_price'] .to_i * multiplier      
        end
        rates
      end
          
      def calculator
        @calculator ||= FedexRate.new
      end      

      def addCoolerCharge(rates, total_charge)
        rates.each do|rate|
          rate['total_price'] = rate['total_price'] .to_i + total_charge      
          total_charge_dollar = total_charge / 100     
          rate['service_name'] =  rate['service_name'] + " (includes $#{total_charge_dollar} refundable cooler deposit)"          
        end
        rates
        
      end
      
      
      def addExtraCharge(rates, total_charge)
        rates.each do|rate|
          rate['total_price'] = rate['total_price'] .to_i + total_charge      
          total_charge_dollar = total_charge / 100         
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
