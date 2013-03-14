class RatesController < ApplicationController

  def shipping_rates
    logger.debug("-------request is" + params.to_s)
    #fedex = FedexRate.new()
    #fedex.get_rates
    rates = {
      :rates:=> 
             {
                 'service_name': 'canadapost-overnight',
                 'service_code': 'ON',
                 'total_price': '12.95',
                 'currency': 'CAD'
             }
      }
    render :json => rates
  end
end  