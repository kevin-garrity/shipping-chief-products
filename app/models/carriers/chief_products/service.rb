module Carriers
  module ChiefProducts
    class Service < ::Carriers::Service
      
      def get_aus_post_final_code(code)
        if (code.include?("SATCHEL"))
          return "AUS_PARCEL_REGULAR" if code.include?("REGULAR_")
          return "AUS_PARCEL_EXPRESS" if code.include?("EXPRESS_")       
        end
        return code
      end
      
      def get_aus_post_rates
         preference = @preference 

         new_items = add_dimension_to_items()         
         service_array = Array.new
         #one lookup per item
         final_list = Array.new
         
         new_items.each do |item|
           quan = item[:quantity].to_i               
           weight = item[:grams].to_i
           
           weight_kg = weight.to_f / 1000
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
          #service_list[1]['service'] is array of hashes
          
          list = Array.new
          service_list[1]['service'].each do |service|
            code = service['code']   
            puts("code is #{code}")         
            price_to_charge = service['price'].to_f * 100 #convert to cents
            shipping_name = shipping_desc[code].blank? ? service['name'] : shipping_desc[code]                        
            
            next unless is_aus_post_service_allowed(shipping_methods, code, weight_kg)
            shipping_name = "Australia Post (#{shipping_name})"
            
            code = "AUS_PARCEL_REGULAR" if code.include?("SATCHEL") && code.include?("REGULAR")
            code = "AUS_PARCEL_EXPRESS" if code.include?("SATCHEL") && code.include?("EXPRESS")
            
            #code = get_aus_post_final_code(code)
            if (final_list.empty?)
              list << { "service_name"=> shipping_name,
                          "service_code"=> code,
                          "total_price"=> price_to_charge * quan.to_f,
                          "currency"=> "AUD"}
            else
              list << { "service_name"=> shipping_name,
                          "service_code"=> code,
                          "total_price"=> price_to_charge * quan.to_f,
                          "currency"=> "AUD"}
              #try to merge with the rates in final_list
              #find service in final_list using service name
              index = final_list.find_index {|item| item['service_name'] == shipping_name}
              final_list[index]['total_price'] =  final_list[index]['total_price'].to_f +  price_to_charge * quan.to_f unless (index.nil?)
            end
          end          
          
          if (final_list.empty?)
            final_list = list 
          else
            #see if any of the rates current in final_list needs to be removed if they are not found within the current array
            final_list.each do |l|
              final_list.delete(l) if (list.find_index {|item| item['service_name'] == l['service_name']}).nil?
            end            
          end
                                                                                      
         end #end each
       
         #remove items that have duplicate service_name
         final_list.each do |l|
           final_list.each do |m|
             final_list.delete(l) if (m != l && m['service_name'] == l['service_name'] && m['service_code'].to_s.include?("SATCHEL"))
           end
         end 

        final_list
      end
      
      # item_weight should be in kg
      def is_aus_post_service_allowed(allowed_methods, service_name, item_weight)

        
        if (allowed_methods[service_name] == 1)
          return true if item_weight > 5.0
          #will fit in prepad satchel]
          if (item_weight > 3.0) # 3 to 5
            return true if service_name.include? ("SATCHEL_5KG")
          elsif (item_weight > 0.5) #0.5 to 3
            return true if service_name.include? ("SATCHEL_3KG")
          else
            return true if service_name.include? ("SATCHEL_500G")            
          end           
        else
          #see if this is a recognized service, if not, allow this to be displayed to the user
          return Preference.AusPostParcelServiceListInt[service_name] == nil && Preference.AusPostParcelServiceListDom[service_name] == nil
        end
        
        return false
        
      end
      
      def fetch_rates
        @carrier_preference = ChiefProductsPreference.find_by_shop_url(@preference.shop_url)
        Rails.logger.debug("#{self.class.name}#fetch_rates")
        new_items = add_dimension_to_items()
        ego_service_list = Array.new
        aus_post_service_list = Array.new
        
        # only offer ego rate for australia destination
        if @carrier_preference.offer_e_go  && destination.country_code.to_s == "AU"
          ego = EgoApiWrapper.new        
          ego_service_list = ego.get_rates(self.origin, self.destination, new_items, @carrier_preference.ego_depot_option)
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
