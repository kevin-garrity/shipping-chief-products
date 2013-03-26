require 'active_shipping'
include ActiveMerchant::Shipping

class RatesController < ApplicationController

  def shipping_rates
    rate = params[:rate]
    if rate.nil?
      render nothing: true
      return
    end
    
    puts("shipping origin is" + rate[:origin].to_s)
    puts("shipping destination is" + rate[:destination].to_s)
    puts("shipping items is" + rate[:items].to_s)

    in_origin = rate[:origin]
    in_dest = rate[:destination]

    origin = Location.new( in_origin)
    #in_dest.merge({ :address_type =>'residential')
    destination = Location.new(in_dest )
                                
    items = params[:rate][:items]
    
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
      
      puts("all samples packages")
      
      weight = 0
      items.each do |item|
        #total all weight
        quan = item[:quantity].to_i
        
        weight = weight + item[:grams].to_i * quan
      end
      # one big package
      packages << Package.new(weight, [])
    
      rates = fedex.get_rates(origin, destination, packages)
      rates_array << rates
      
    else    
      items.each do |item|
        # treat each item as seperate 
        packages = Array.new      
        fedex = FedexRate.new()
        quan = item[:quantity].to_i
      
        # get the number of items being ordered
        if (item[:sku].include?("SAM/")) #shipped together
          packages << Package.new(item[:grams].to_i * quan, [])
          rates = fedex.get_rates(origin, destination, packages)
        else
          # look up one package and multiple by quantity
          puts("quan is " + quan.to_s)

          packages << Package.new(item[:grams].to_i, [])
          single_rate = fedex.get_rates(origin, destination, packages) 
          rates = single_rate.collect do | rate|
            {"service_name" => rate["service_name"], 'service_code'=> rate["service_code"], 'total_price' => rate["total_price"].to_i * quan, 'currency' => rate["currency"]}
          end
          puts ("multiple rates is " + rates.to_s)
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
        
    #puts("----- returning " + rates.to_json)
    render :json => {:rates => find_rates.values}
  rescue ActiveMerchant::Shipping::ResponseError => e
    puts e.message
    render nothing: true
  end
end
