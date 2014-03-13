module Carriers
  module ChiefProducts
    class Service < ::Carriers::Service

      def get_aus_post_rates
         preference = @preference 

         new_items = add_dimension_to_items()         
         service_array = Array.new
         #one lookup per item
         #make one query to fedex
         new_items.each do |item|
           quan = item[:quantity].to_i               
           weight = item[:grams].to_i * quan
           
           weight_kg = weight / 1000
           @australia_post_api_connection = AustraliaPostApiConnection.new({:weight=> weight_kg,
                                                                           :from_postcode => origin.postal_code,
                                                                           :country_code =>  destination.country_code.to_s,
                                                                           :to_postcode => destination.postal_code,
                                                                           :height=>item[:height], :width=>item[:width], :length=>item[:length],
                                                                           :container_weight => 0.0 })
          @australia_post_api_connection.domestic = ( destination.country_code.to_s == "AU" )
          
          if @australia_post_api_connection.domestic
             shipping_methods = preference.shipping_methods_allowed_dom
             shipping_desc = preference.shipping_methods_desc_dom
           else
             shipping_methods = preference.shipping_methods_allowed_int
             shipping_desc = preference.shipping_methods_desc_int
           end           

          service_list = @australia_post_api_connection.data_oriented_methods(:service) # get the service list
          service_list = Array.wrap( service_list[1]['service'] ).inject([]) do |list, service|
              Rails.logger.debug("service code is " + service['code'])              
              code = service['code']
              if shipping_methods[code]
                price_to_charge = service['price'].to_f
                shipping_name = shipping_desc[code].blank? ? service['name'] : shipping_desc[code]


                list.append({ "service_name"=> shipping_name,
                            "service_code"=> code,
                            "total_price"=> price_to_charge,
                            "currency"=> "AUD"})
              end

              list
            end
            
            service_array << service_list                                                                                       
         end #end each
               
        service_array
      end
      
      
      def fetch_rates
        @carrier_preference = ChiefProductsPreference.find_by_shop_url(@preference.shop_url)
        Rails.logger.debug("#{self.class.name}#fetch_rates")
        new_items = add_dimension_to_items()
        ego_service_list = Array.new
        aus_post_service_list = Array.new
        
        if @carrier_preference.offer_e_go        
          ego = EgoApiWrapper.new        
          ego_service_list = ego.get_rates(self.origin, self.destination, new_items, "")
          puts("ego_service_list is #{ego_service_list}")
          ego_service_list = consolidate_rates(ego_service_list)          
          
          puts("consolided ego_service_list is #{ego_service_list}")
          
        end
        if (@carrier_preference.offer_australia_post)
          aus_post_service_list = get_aus_post_rates().flatten
          
          puts("aus_post_service_list is #{ aus_post_service_list}")          
          aus_post_service_list = consolidate_rates(aus_post_service_list)                              
        end
 
        
        
        list = ego_service_list.concat(aus_post_service_list)
        puts("consoidated list is #{list}")
        
        return list
      end
    
      # go to shopify metafields and get the product dimension
      def add_dimension_to_items
        new_items = Array.new
        items.each do |i|
          p = CachedProduct.find_by_product_id(i[:product_id])
          i = i.merge({:height=>p.height, :width=>p.width, :length =>p.length})
          new_items << i
        end
        new_items
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


    end    
  end
end
