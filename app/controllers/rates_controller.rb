class RatesController < ApplicationController

  def shipping_rates
    puts("-------request is" + params.to_s)
    #fedex = FedexRate.new()
    #fedex.get_rates

    rate_array = Array.new
    rate_array << 
    {
       'service_name': 'canadapost-overnight',
       'service_code': 'ON',
       'total_price': '12.95',
        'currency': 'USD'
    }
    
    rate_array << 
    {
       'service_name': 'canadapost-2dayground',
       'service_code': '1D',
       'total_price': '29.34',
        'currency': 'USD'
    }
    
    render :json => {:rates => rate_array.to_json}
  end
end  