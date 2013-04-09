module Carriers
  module Fabusa
    class Service < ::Carriers::Service

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
              logger.info('adding rate' + (r["total_price"].to_i + find_rates[r["service_name"]]["total_price"].to_i).to_s)
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
        case destination.country
        when 'US'
          calculator = FedexRate.new
        else
          calculator = UpsRate.new
        end
      end      
    end    
  end
end
