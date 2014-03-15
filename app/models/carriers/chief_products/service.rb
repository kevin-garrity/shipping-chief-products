module Carriers
  module ChiefProducts
    class Service < ::Carriers::Service

      def get_aus_post_rates
         preference = @preference 

         new_items = add_dimension_to_items()         
         service_array = Array.new
         #one lookup per item
         final_list = Array.new
         
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
          puts("service_list is " + pp(service_list[1].to_s))
          
          #service_list[1]['service'] is array of hashes
          
          
          list = Array.new
          service_list[1]['service'].each do |service|
            code = service['code']            
            price_to_charge = service['price'].to_f
            shipping_name = shipping_desc[code].blank? ? service['name'] : shipping_desc[code]
            
            if (final_list.empty?)
              list << { "service_name"=> shipping_name,
                          "service_code"=> code,
                          "total_price"=> price_to_charge,
                          "currency"=> "AUD"}
            else
              list << { "service_name"=> shipping_name,
                          "service_code"=> code,
                          "total_price"=> price_to_charge,
                          "currency"=> "AUD"}
              #try to merge with the rates in final_list
              #find service in final_list using service code
              index = final_list.find_index {|item| item['service_code'] == code}
              final_list[index]['total_price'] =  final_list[index]['total_price'].to_f +  price_to_charge unless (index.nil?)
            end
          end          
          
          if (final_list.empty?)
            final_list = list 
          else
            #see if any of the rates current in final_list needs to be removed if they are not found within the current array
            final_list.each do |l|
              final_list.delete(l) if (list.find_index {|item| item['service_code'] == l['service_code']}).nil?
            end            
          end
                                                                                      
         end #end each
#        puts("final_array is " + final_list.to_s)
        final_list
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
          ego_service_list = consolidate_rates(ego_service_list)                              
        end
        if (@carrier_preference.offer_australia_post)
          aus_post_service_list = get_aus_post_rates()          
        end
                 
        list = ego_service_list.concat(aus_post_service_list)
        puts("consoidated list is #{list}")
        
        return list
      end
    
      # get the product dimensions
      def add_dimension_to_items
        new_items = Array.new
        items.each do |i|
          p = CachedProduct.find_by_product_id(i[:product_id])
          i = i.merge({:height=>p.height, :width=>p.width, :length =>p.length})
          new_items << i
        end
        new_items
      end
    end
  end
end
