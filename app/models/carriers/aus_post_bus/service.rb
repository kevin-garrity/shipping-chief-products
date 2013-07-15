module Carriers
  module AusPostBus
    class Service < ::Carriers::Service
      
      def fetch_rates   
        preference = @preference 
        
        @australia_post_api_connection = AustraliaPostApiConnection.new({
          from_postcode: preference.origin_postal_code,
          height: preference.height,
          width: preference.width,
          length: preference.length
        })                     
         quan = 0
         weight = 0
         # get all the items weight
         items.each do |item|
           quan = item[:quantity].to_i               
           weight = weight + item[:grams].to_i * quan
         end
         calculated_weight = weight
         rate_list = Array.new

         if (preference.offers_flat_rate)                            
           if (calculated_weight <= preference.under_weight)
             rate_list << { service_name: "Shipping",
                           service_code: "Shipping",
                           total_price: preference.flat_rate.to_s,
                           currency: "AUD"}
             return
           end
         end
         
         puts("destination.country is" + destination.country_code.to_s)

         @australia_post_api_connection = AustraliaPostApiConnection.new({:weight=> calculated_weight,
                                                                         :from_postcode => preference.origin_postal_code,
                                                                         :country_code =>  destination.country_code.to_s,
                                                                         :to_postcode => destination.postal_code,
                                                                         :height=>preference.height, :width=>preference.width, :length=>preference.length,
                                                                         :container_weight => preference.container_weight
         })

         @australia_post_api_connection.domestic = ( destination.country_code.to_s == "AU" )

         # get country list from the API -- we'll format these if there were no errors
         @service_list = @australia_post_api_connection.data_oriented_methods(:service) # get the service list

         if @australia_post_api_connection.domestic
           shipping_methods = preference.shipping_methods_allowed_dom
           shipping_desc = preference.shipping_methods_desc_dom
         else
           shipping_methods = preference.shipping_methods_allowed_int
           shipping_desc = preference.shipping_methods_desc_int
         end

         if @australia_post_api_connection.save
           @service_list = Array.wrap( @service_list[1]['service'] ).inject([]) do |list, service|
             Rails.logger.debug("service code is " + service['code'])
             if shipping_methods[service['code']]
               price_to_charge = service['price'].to_f
               shipping_name = shipping_desc[service['code']].blank? ? service['name'] : shipping_desc[service['code']]
               unless preference.nil?
                 unless preference.surcharge_percentage.nil?
                   if preference.surcharge_percentage > 0.0
                     price_to_charge =(price_to_charge * (1 + preference.surcharge_percentage/100)).round(2)
                   end
                 end

                 unless preference.surcharge_amount.nil?
                   if preference.surcharge_amount > 0.0
                     price_to_charge = (price_to_charge + preference.surcharge_amount).round(2)
                   end
                 end
               end

               list.append({ service_name: shipping_name,
                           service_code: service['code'],
                           total_price: price_to_charge,
                           currency: "AUD"})
                           
             end # if shipping_methods[service['code']]
             Rails.logger.debug("  list " +    list.to_s)

             list
           end
           
           Rails.logger.debug("   @service_list is " +    @service_list.to_s)           

           # check if need to add free shipping option
           if (preference.free_shipping_option)
              @service_list.append({ service_name: preference.free_shipping_description,
                           service_code: "Free",
                           total_price: "0.00",
                            currency: "AUD"})
           end
         end
         
        Rails.logger.debug("   @service_list is " +    @service_list.to_s)
         @service_list
      end   #end def fetch_rates
      
    end    
  end
end
