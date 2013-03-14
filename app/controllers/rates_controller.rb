require 'active_shipping'
include ActiveMerchant::Shipping

class RatesController < ApplicationController

  def shipping_rates

    in_origin = params[:rate][:origin]
    in_dest = params[:rate][:destination]

    origin = Location.new( in_origin)
    destination = Location.new( in_dest)
                                
    items = params[:rate][:items]
    
    total = 0
    rates_array = Array.new
    items.each do |item|
      # treat each item as seperate 
      packages = Array.new      
      packages << Package.new(item[:grams].to_i, [])
      fedex = FedexRate.new()
      rates = fedex.get_rates(origin, destination, packages)
      rates_array << rates
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
  end
end
