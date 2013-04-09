class RatesController < ApplicationController

  #this is the rules for foldaboxUSA store only
  def shipping_rates    
    preference = Preference.find_by_shop_url(params[:shop_url])    
    return nothing unless params[:rate] && preference

    log_params

    service_class = carrier_service_class_for(@preference.carrier)
    service = service_class.new(params[:rate])

    rates = service.fetch_rates

        
    #Rails.logger.debug("----- returning " + rates.to_json)
    render :json => {:rates => rates}
  rescue ActiveMerchant::Shipping::ResponseError => e
    Rails.logger.debug e.message
    render nothing: true
  end

  private
  def log_params
    Rails.logger.debug("shipping origin is" + rate[:origin].to_s)
    Rails.logger.debug("shipping destination is" + rate[:destination].to_s)
    Rails.logger.debug("shipping items is" + rate[:items].to_s)
  end

  def nothing
    render nothing: true
  end
end
