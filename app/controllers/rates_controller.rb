class RatesController < ApplicationController
  include CarrierHelper

  def shipping_rates 
    shop_domain = request.headers['HTTP_X_SHOPIFY_SHOP_DOMAIN']
    Rails.logger.info("shop_domain: #{shop_domain}")
    
    shop = Shop.find_by_url(shop_domain)
    preference = Preference.find_by_shop(shop) 
    Rails.logger.info("preference: #{preference.inspect}")
    return nothing unless params[:rate] && preference

    log_params

    service_class = carrier_service_class_for(preference.carrier, preference.client_config)
    service = service_class.new(preference, params[:rate])

    rates = service.fetch_rates
    ppl rates
    Rails.logger.debug("----- returning " + rates.to_json)
    render :json => {:rates => rates}
  rescue ActiveMerchant::Shipping::ResponseError => e
    Rails.logger.debug e.message
    render nothing: true
  end

  private
  def log_params
    Rails.logger.debug("shipping origin is" + params[:rate][:origin].to_s)
    Rails.logger.debug("shipping destination is" + params[:rate][:destination].to_s)
    Rails.logger.debug("shipping items is" + params[:rate][:items].to_s)
  end

  def nothing
    render nothing: true
  end
end
