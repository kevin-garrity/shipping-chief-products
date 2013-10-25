module Carriers
  module Ridgewood
    
    class Service < ::Carriers::Service    

      def get_ridgewood_preference
        RidgewoodPreference.find_by_shop(self.shop)
      end

      def get_calculator
        cal = ActiveMerchant::Shipping::USPS.new(:login=>"337RIDGE0587", :test =>false, commercial_base:true)        
      end
      
      def is_domestic
         return destination.country.to_s == "United States"
      end
      
      def is_canada
         return destination.country.to_s == "Canada"
      end
      
      
      def fetch_rates
        
        ridge_preference = get_ridgewood_preference
        rate_array = Array.new
        withShopify do
          
          cal = get_calculator
          flat_rate = 0.0
            # get all the collections by looking at pattern XXX-
          items.each do |item|
            match = item[:sku].include?('CLASSIC')
            if match
              
              Rails.logger.debug("----Getting rates for CLASSIC shipping ")
              
              #flat rate shipping
              quan = item[:quantity].to_i               

              if (is_domestic)
                rate_array << {:service_name => "USPS Priority Mail 2-Day", :total_price => ridge_preference.in_cents(:domestic_regular_flat_rate) * quan, :currency => self.get_currency, :service_code=>"NA" }
                rate_array << {:service_name => "USPS Priority Mail Express 2-Day", :total_price => ridge_preference.in_cents(:domestic_express_flat_rate) * quan, :currency => self.get_currency, :service_code=>"NA" }
              else
                if (is_canada)
                  rate_array << {:service_name => "USPS Priority Mail International", :total_price => ridge_preference.in_cents(:international_flat_rate_canada) * quan, :currency => self.get_currency, :service_code=>"NA" }
                else
                  remaining_quan = quan
                  charge = 0
                  
                  flat_rate_1 = ridge_preference.in_cents(:international_flat_rate)                  
 
                  
                   #real time rate shipping if quantity is more than 2
                  weight = item[:grams].to_i
                  
                  if remaining_quan >= 5
                    multiple = (remaining_quan.to_i / 5).to_i
                    packages = Array.new
                    #look up flat_rate_5
                    packages << ActiveMerchant::Shipping::Package.new(Quantified::Mass.new(weight * 5, :grams), [ridge_preference.length_3, ridge_preference.width_3, ridge_preference.height_3].map {|m| Quantified::Length.new(m, :inches)} ) 
                    response = cal.find_rates(origin, destination, packages)                      
                    rates = remove_unoffered_rates(response.rates)              
                                        
                    puts("rates[0].price.to_i is " + rates[0].price.to_i.to_s)
                    charge += multiple * rates[0].price.to_i
                    remaining_quan = remaining_quan % 5
                    response = nil
                  end
                                  
                  if remaining_quan == 4
                    multiple = (remaining_quan.to_i / 4).to_i
                    packages = Array.new
                    packages << ActiveMerchant::Shipping::Package.new(Quantified::Mass.new(weight * 4, :grams), [ridge_preference.length_3, ridge_preference.width_3, ridge_preference.height_3].map {|m| Quantified::Length.new(m, :inches)} ) 
                    response = cal.find_rates(origin, destination, packages)                      
                    rates = remove_unoffered_rates(response.rates)
                  
                    charge += multiple * rates[0].price.to_i
                    puts("rates[0].price.to_i is " + rates[0].price.to_i.to_s)
                    
                    remaining_quan = remaining_quan % 4
                  end                  
                
                  if remaining_quan == 3
                    multiple = (remaining_quan.to_i / 3).to_i
                    packages = Array.new
                    packages << ActiveMerchant::Shipping::Package.new(Quantified::Mass.new(weight * 3, :grams), [ridge_preference.length_2, ridge_preference.width_2, ridge_preference.height_2].map {|m| Quantified::Length.new(m, :inches)} ) 
                    response = cal.find_rates(origin, destination, packages)                      
                    rates = remove_unoffered_rates(response.rates)
                  
                    charge += multiple * rates[0].price.to_i
                    puts("rates[0].price.to_i is " + rates[0].price.to_i.to_s)
                    
                    remaining_quan = remaining_quan % 3
                  end
                
                  if remaining_quan == 2
                    multiple = (remaining_quan.to_i / 2).to_i
                    packages = Array.new
                  
                    packages << ActiveMerchant::Shipping::Package.new(Quantified::Mass.new(weight * 2, :grams), [ridge_preference.length_2, ridge_preference.width_2, ridge_preference.height_2].map {|m| Quantified::Length.new(m, :inches)} ) 
                    response = cal.find_rates(origin, destination, packages)                      
                    rates = remove_unoffered_rates(response.rates)
                  
                    charge += multiple * rates[0].price.to_i
                    puts("rates[0].price.to_i is " + rates[0].price.to_i.to_s)
                    
                    remaining_quan = remaining_quan % 2
                  end
                
                  if remaining_quan == 1
                    multiple = 1
                    charge += multiple * flat_rate_1
                    remaining_quan = 0
                  end
                    
                 
                  
                 rate_array << {:service_name => "USPS Priority Mail International", :total_price => charge, :currency => self.get_currency, :service_code=>"NA" }
                  
                end  
              end                          
            end
            
            match = item[:sku].include?('SPECIALEDITION')
            if match
              Rails.logger.debug("---- Getting rates for real time shipping ")
              #real time rate shipping
              quan = item[:quantity].to_i               
              weight = item[:grams].to_i
              packages = Array.new      
              
              packages << ActiveMerchant::Shipping::Package.new(Quantified::Mass.new(weight, :grams), [@preference.length, @preference.width, @preference.height].map {|m| Quantified::Length.new(m, :inches)} ) 
              response = cal.find_rates(origin, destination, packages)
              
              if (is_domestic)              
                rates = response.rates.select {|r| r.service_name.include?("USPS Priority Mail") || r.service_name.include?("USPS Priority Mail Express")}
                rates.delete_if {|r| r.service_name.include?("Hold For Pickup") }

                # only show one express rate (most expensive one)
                express_rates = rates.select {|r| r.service_name.include?("USPS Priority Mail Express 1-Day") || r.service_name.include?("USPS Priority Mail Express 2-Day")}
                
                if (express_rates.size > 1)
                  rates.delete_if {|r| r.service_name.include?("USPS Priority Mail Express 2-Day") }                  
                end                
              else
                rates = remove_unoffered_rates(response.rates)              
              end

              ret_rates = rates.sort_by(&:price).collect do |rate|
                service_name = rate.service_name
                
                #change to match the description for regular so the rates can be merged properly We want to show rates as 1-3 days .                              
                service_name = "USPS Priority Mail Express 2-Day" if (rate.service_name == "USPS Priority Mail Express 1-Day")
                service_name = "USPS Priority Mail 2-Day" if (rate.service_name == "USPS Priority Mail 1-Day")
                
                {:service_name => service_name, :service_code=> 'NA', :total_price => rate.price.to_i, :currency => rate.currency}
                  
              end

              ret_rates = multiple_charge(ret_rates, quan) if (quan > 1)
              
              rate_array.concat(ret_rates)
            end
          end
                    
          rate_array = consolidate_rates(rate_array)          
          Rails.logger.debug("---- Returning rates as " + rate_array.to_s)
          
        end # end with shopify
        
        rate_array.map do |r|
          { :service_name => r[:service_name].sub("Priority Mail Express 2-Day", "Priority Mail Express ( 1-2 Days)").sub("Priority Mail 2-Day", "Priority Mail( 1-3 Days)"),
            :service_code => r[:service_code], :total_price => r[:total_price], :currency => r[:currency]
          }
        end
        
      end
      
      def remove_unoffered_rates(rates)
        ret_rates = rates.select {|r| r.service_name.include?("International")}
        ret_rates.delete_if {|r| r.service_name.include?("Special") ||   r.service_name.include?("Priority Mail Express International") }
      end

      def consolidate_rates(rates_array)
        find_rates = Array.new
        #go through all the rates and total them up
        rates_array.each do |r|          
            found = find_rates.select do |f| 
              f[:service_name].to_s == r[:service_name].to_s 
            end
                        
            if (found.size == 0)
              find_rates << r              
            else                   
              r[:total_price] = r[:total_price].to_i + found[0][:total_price].to_i
              find_rates.delete(found[0])
              find_rates << r
            end 
        end # end rates_array.each
        find_rates
      end
    

      def multiple_charge(rates, multiplier)
        rates.each do|rate|
          rate[:total_price] = rate[:total_price] .to_i * multiplier      
        end
        rates
      end

    end    
  end
end
