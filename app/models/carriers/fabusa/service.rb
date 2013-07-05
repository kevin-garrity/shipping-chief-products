module Carriers
  module Fabusa
    class Service < ::Carriers::Service
      
      def get_single_rate(origin, destination, shipping_item)
        quan = shipping_item[:quantity].to_i
        calculator = get_calculator
        
        packages = Array.new      
                    
        if (shipping_item[:sku].include?("SAM/")) #shipped together. Get weight of all items together
          packages << Package.new(shipping_item[:grams].to_i * quan, [])
          multipler = 1
        else
          packages << Package.new(shipping_item[:grams].to_i, [])              
          multipler = quan
        end
        
        rates = calculator.get_rates(origin, destination, packages)
        
        rates = rates.collect do | rate|
           service_name = rate["service_name"]
           #remove fedex or ups brand name
           service_name = service_name.gsub(/(FedEx )/, '').gsub(/(Home )/, '')
           service_name = service_name.gsub(/(UPS )/, "INT'L ")

           {"service_name" => service_name, 'service_code'=> rate["service_code"], 'total_price' => rate["total_price"].to_i * multipler, 'currency' => rate["currency"]}
         end                 
        rates                     
      end
      
      def fetch_rates
        Rails.logger.debug("service_host is " + preference.shop_url.to_s)
        total = 0
        rates_array = Array.new
        all_samples = true
        service_host =  preference.client_config.service_host
        
        #check if all items are of sample
        
        items_count = items.length
        
        shipping_items = items
        
        #hack ask richard...                        
        if (shipping_items.class == HashWithIndifferentAccess )
          new_items = Array.new          
          new_items << shipping_items["0"]
          shipping_items = new_items
        end
        
        shipping_items.each do |item|          
          Rails.logger.debug("item[:sku] is " + item[:sku])       
          if (!item[:sku].include?("SAM/")) #shipped together
            all_samples = false        
          end
        end
        
        if (all_samples) # all shipped together total them up as one package
          packages = Array.new
          sample_item = shipping_items[0]
                    
          weight = 0
          shipping_items.each do |item|
            #total all weight
            quan = item[:quantity].to_i            
            weight = weight + item[:grams].to_i * quan
          end
          # one big package
          sample_item[:quantity] = 1
          sample_item[:grams] = weight
                  
          rates = get_single_rate(origin, destination, sample_item)          
          rates_array << rates
          
        else          
          hydra = Typhoeus::Hydra.hydra
         
          if (items_count == 1)                     
            rates = get_single_rate(origin, destination, shipping_items[0])                          
            rates_array << rates                  
          else #iterate through and use hydra to fetch them concurrently
            shipping_items.each do |item|
             item_array = Array.new
             item_array << item
                                      
              post_rates = {:origin => params[:origin] , :destination => params[:destination], :items => item_array.as_json}
                  #use Typhoeus to parallel the request
                  request = Typhoeus::Request.new(
                    service_host+"/shipping-rates",
                    method: :post,
                    params: {:rate => post_rates
                       },                  
                    headers: { Accept: "text/html",
                      HTTP_X_SHOPIFY_SHOP_DOMAIN: preference.shop_url }
                  )
                
                  request.on_complete do |response|
                    if response.success?
                      # hell yeah
                      parsed_rates = JSON.parse(response.body)["rates"]
                      Rails.logger.debug("got response is" + parsed_rates.to_s)    
                      rates_array << parsed_rates                
                    elsif response.timed_out?
                      # aw hell no
                      Rails.logger.debug("got a time out")
                    elsif response.code == 0
                      # Could not get an http response, something's wrong.
                      Rails.logger.debug(response.curl_error_message)
                    else
                      # Received a non-successful http response.
                      Rails.logger.debug("HTTP request failed: " + response.code.to_s)
                    end
                  end
                
                  hydra.queue(request)
           
              if (items_count == 1)            
                rates_array << rates
              end
            end #end items.each
          end
        end
        
        if (items_count > 1 && !all_samples)
          hydra.run
        end
        
        find_rates = Hash.new
        #go through all the rates and total them up
        rates_array.each do |rate|
          rate.each do |r|
            if (find_rates.has_key?(r["service_name"]))     
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

      def get_calculator
        country = destination.country.to_s
        case country
        when 'United States'
          case destination.province
           when 'AS', 'GU', 'MP', 'PR', 'VI', 'UM', 'FM', 'MH', 'PW', 'AA', 'AE', 'AP', 'CM'
             calculator = FabusaUpsRate.new
           else
             calculator = FabusaFedexRate.new
          end
        else
          calculator = FabusaUpsRate.new
        end        
        calculator
      end
      
    end    
  end
end
