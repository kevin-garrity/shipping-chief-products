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
      
      def fetch_rates
        
        ridge_preference = get_ridgewood_preference
        rate_array = Array.new
        withShopify do
          
          cal = get_calculator
          flat_rate = 0.0
            # get all the collections by looking at pattern XXX-
          items.each do |item|
            match = item[:sku].include?('REGULAR')
            if match
              #flat rate shipping
              quan = item[:quantity].to_i               

              if (is_domestic)
                rate_array << {:service_name => "USPS Priority Mail 2-Day", :total_price => ridge_preference.in_cents(:domestic_regular_flat_rate) * quan, :currency => self.get_currency, :service_code=>"NA" }
                rate_array << {:service_name => "USPS Priority Mail Express 2-Day", :total_price => ridge_preference.in_cents(:domestic_express_flat_rate) * quan, :currency => self.get_currency, :service_code=>"NA" }
              else
                rate_array << {:service_name => "USPS Priority Mail International", :total_price => ridge_preference.in_cents(:international_flat_rate) * quan, :currency => self.get_currency, :service_code=>"NA" }
              end                          
            end
            
            match = item[:sku].include?('SPECIALEDITION')
            if match
              
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
                rates = response.rates.select {|r| r.service_name.include?("International")}

                rates.delete_if {|r| r.service_name.include?("Special") ||   r.service_name.include?("Priority Mail Express International") }
                
              end

              ret_rates = rates.sort_by(&:price).collect do |rate|
                service_name = rate.service_name
                
                #change to match the description for regular so the rates can be merged properly
                service_name = "USPS Priority Mail Express 2-Day" if (rate.service_name == "USPS Priority Mail Express 1-Day")
                {:service_name => service_name, :service_code=> 'NA', :total_price => rate.price.to_i, :currency => rate.currency}
                  
              end              

              ret_rates = multiple_charge(ret_rates, quan) if (quan > 1)
              
              rate_array.concat(ret_rates)
            end
          end
                    
          rate_array = consolidate_rates(rate_array)          
          
        end # end with shopify
        
        rate_array.map do |r|
          { :service_name => r[:service_name].sub("Priority Mail Express 2-Day", "Priority Mail Express ( 1-2 Days)").sub("Priority Mail 2-Day", "Priority Mail( 1-3 Days)"),
            :service_code => r[:service_code], :total_price => r[:total_price], :currency => r[:currency]
          }
        end
        
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
