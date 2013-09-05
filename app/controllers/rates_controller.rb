class RatesController < ApplicationController
  include CarrierHelper

  def shipping_rates 
    preference = get_shop_prefence_from_request
   # log_params
    return nothing unless params[:rate] && preference

    service_class = carrier_service_class_for(preference.carrier, preference.client_config)
    service = service_class.new(preference, params[:rate])
    
    rates = service.fetch_rates

    render :json => {:rates => rates}
  rescue ActiveMerchant::Shipping::ResponseError => e
    Rails.logger.debug e.message
    render nothing: true
  end

  private
  
  def get_shop_prefence_from_request()
    shop_domain = get_shop_domain_from_request
    shop = Shop.find_by_url(shop_domain)
    preference = Preference.find_by_shop(shop)
    preference
  end
  
  def get_shop_domain_from_request
    request.headers['HTTP_X_SHOPIFY_SHOP_DOMAIN']
  end
  
  def log_params    
    Rails.logger.debug("shipping origin is" + params[:rate][:origin].to_s)
    Rails.logger.debug("shipping destination is" + params[:rate][:destination].to_s)
    Rails.logger.debug("shipping items is" + params[:rate][:items].to_s)
  end

  def nothing
    render nothing: true
  end
end
