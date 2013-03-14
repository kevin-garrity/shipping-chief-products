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
    packages = Array.new
    items.each do |item|
      packages << Package.new(item[:grams], [])
    end
   
   # packages = [
  #    Package.new(  100,                        # 100 grams
  #                  [93,10],                    # 93 cm long, 10 cm diameter
  #                  :cylinder => true),         # cylinders have different volume calculations

  #    Package.new(  (7.5 * 16),                 # 7.5 lbs, times 16 oz/lb.
  #                  [15, 10, 4.5],              # 15x10x4.5 inches
  #                  :units => :imperial)        # not grams, not centimetres
  #  ] 
  
  puts("--packages is " + packages.to_s)
  
    fedex = FedexRate.new()
    rates = fedex.get_rates(origin, destination, packages)
    puts("--rate from fedex is " + rates.to_s)
        
    #puts("----- returning " + rates.to_json)
    render :json => {:rates => rates}
  end
end  