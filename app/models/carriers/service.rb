require 'active_shipping'
# TODO: I really dislike including things in the global namespace. Then I have to go look up the code and make sure this is just a module with classes and isn't defining random methods that might mysteriously with my own
include ActiveMerchant::Shipping

module Carriers
  class Service
    include CarrierHelper
    
    attr_accessor :preference, :params

    def initialize(preference, params)
      @preference = preference
      @params = params.symbolize_keys     
    end

    #return location origin class
    def origin      
      @origin ||= Location.new(params[:origin])
    end

    #return activeshipping location obj
    def destination
      @destination ||= Location.new(params[:destination])
    end
    
    def get_currency    
      params[:currency]
    end

    def items
      params[:items]
    end

    def shop
      @shop ||= Shop.find_by_url(preference.shop_url)
    end

    def withShopify
      ShopifyAPI::Session.temp(shop.myshopify_domain, shop.token) do
        yield
      end
    end
    

    def fetch_rates
      #  implement in subclasses
    end

    # give a array of rates, find items that have the same service name and total the total_price
    def consolidate_rates(rates_array)
       find_rates = Array.new
       #go through all the rates and total them up
       rates_array.each do |r|          
           found = find_rates.select do |f| 
             f["service_code"].to_s == r["service_code"].to_s 
           end
                       
           if (found.size == 0)
             find_rates << r              
           else                   
             r["total_price"] = r["total_price"].to_f + found[0]["total_price"].to_f
             find_rates.delete(found[0])
             find_rates << r
           end 
       end # end rates_array.each
       find_rates
    end

  end
end