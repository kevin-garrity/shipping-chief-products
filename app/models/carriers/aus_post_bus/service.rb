module Carriers
  module AusPostBus
    class Service < ::Carriers::Service
      
      def fetch_rates
        url = params[:shop_url]
        
        preference = Preference.find_by_shop_url!(url)
        
        @australia_post_api_connection = AustraliaPostApiConnection.new({
          from_postcode: preference.origin_postal_code,
          height: preference.height,
          width: preference.width,
          length: preference.length
        })        
        
        # recalculate the weight to include blanks
         calculated_weight = params[:australia_post_api_connection][:blanks].to_i * preference.default_weight.to_f
         calculated_weight += params[:australia_post_api_connection][:weight].to_f
         params[:australia_post_api_connection][:blanks] = '0'
         params[:australia_post_api_connection][:weight] = calculated_weight.to_s
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

         weight = weight
         @australia_post_api_connection = AustraliaPostApiConnection.new({:weight=> params[weight],
                                                                         :from_postcode => preference.origin_postal_code,
                                                                         :country_code =>  @destination[:country],
                                                                         :to_postcode => @destination[:postal_code],
                                                                         :height=>preference.height, :width=>preference.width, :length=>preference.length,
                                                                         :container_weight => preference.container_weight
         })

         @australia_post_api_connection.domestic = ( @australia_post_api_connection.country_code == "AUS" )

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
             @countries = get_country_list(@australia_post_api_connection)

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
                             price: price_to_charge},
                             currency: "AUD")
               end

               list
             end

             # check if need to add free shipping option
             if (preference.free_shipping_option)
                @service_list.append({ name: preference.free_shipping_description,
                             code: "Free",
                             total_price: "0.00"})
             end
         end
          
      end
      
      def fetch_rates
        total = 0
        rates_array = Array.new
        all_samples = true
        #check if all items are of sample
        items.each do |item|
          if (!item[:sku].include?("SAM/")) #shipped together
            all_samples = false        
          end
        end
        
        if (all_samples)
          packages = Array.new
          
          Rails.logger.debug("all samples packages")
          
          weight = 0
          items.each do |item|
            #total all weight
            quan = item[:quantity].to_i
            
            weight = weight + item[:grams].to_i * quan
          end
          # one big package
          packages << Package.new(weight, [])
        
          rates = calculator.get_rates(origin, destination, packages)
          rates_array << rates
          
        else    
          items.each do |item|
            # treat each item as seperate 
            packages = Array.new      
            quan = item[:quantity].to_i
          
            # get the number of items being ordered
            if (item[:sku].include?("SAM/")) #shipped together
              packages << Package.new(item[:grams].to_i * quan, [])
              rates = calculator.get_rates(origin, destination, packages)
            else
              # look up one package and multiple by quantity
              Rails.logger.debug("quan is " + quan.to_s)

              packages << Package.new(item[:grams].to_i, [])
              single_rate = calculator.get_rates(origin, destination, packages) 
              rates = single_rate.collect do | rate|
                service_name = rate["service_name"]
                
                #remove fedex or ups brand name
                service_name = service_name.gsub(/(FedEx )/, '').gsub(/(Home )/, '')
                service_name = service_name.gsub(/(UPS )/, "INT'L ")
                
                {"service_name" => rate["service_name"], 'service_code'=> rate["service_code"], 'total_price' => rate["total_price"].to_i * quan, 'currency' => rate["currency"]}
              end
              Rails.logger.debug("multiple rates is " + rates.to_s)
            end
            rates_array << rates
          end
        end
        
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
          end
        end
        find_rates.values
      end

      def calculator
        @calculator ||= case destination.country
        when 'US'
          case destination.province
           when 'AS', 'GU', 'MP', 'PR', 'VI', 'UM', 'FM', 'MH', 'PW', 'AA', 'AE', 'AP', 'CM'
            
           else
                     
          end
        else
      
        end
      end
      
    end    
  end
end
