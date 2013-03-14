class RatesController < ApplicationController

  def shipping_rates
    logger.debug("-------request is" + params.to_s)
    #fedex = FedexRate.new()
    #fedex.get_rates
  end
end  