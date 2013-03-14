require 'active_shipping'
include ActiveMerchant::Shipping

class RatesController < ApplicationController

  def shipping_rates
    puts("-------request is" + params.to_s)

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
      packages << Package.new(item[:grams], [])
      fedex = FedexRate.new()
      rates = fedex.get_rates(origin, destination, packages)
      rates_array << rates
    end
    
    find_rates = Hash.new
    #go through all the rates and total them up
    rates_array.each do |rate|
      rate.each do |r|
        if (find_rates[rate[:service_name])
          find_rates[rate.service_name] = {:service_name =>rate[:service_name], :service_code=>rate[:service_code], :total_price => rate[:total_price] + find_rates[rate.service_name][:total_price]  , :currency => rate[:currency]}
        else
          find_rates[rate.service_name] = {:service_name =>rate[:service_name], :service_code=>rate[:service_code], :total_price => rate[:total_price], :currency => rate[:currency]}
        end
      end
    end
    puts("--rate from fedex is " + rates_array.values.to_s)
        

    #puts("----- returning " + rates.to_json)
    render :json => {:rates => rates_array.values}
  end
end
