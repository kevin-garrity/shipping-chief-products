class ApplicationController < ActionController::Base
  protect_from_forgery
  
  private
    def current_shop
      return nil unless session[:shopify]
      @shop ||= Shop.find_by_url(session[:shopify].shop.domain)
    end
    
    def check_payment


      if (Rails.env == "production")
        if (!ShopifyAPI::RecurringApplicationCharge.current && default_client?  \
          && !session[:shopify].url.include?("dev-shop") \
          && !session[:shopify].url.include?("schumm-durgan-and-lang94") \
          && !session[:shopify].url.include?("lifemap") \
          )
            #place a recurring charge
          charge = ShopifyAPI::RecurringApplicationCharge.create(:name => "Shipping Calculator Application", 
                                                             :price => 15, 
                                                             :test=>(Rails.env != "production"),
                                                             :trial_days => 30,
                                                             :return_url => "http://#{DOMAIN_NAMES[Rails.env]}/confirm_charge")

          redirect_to charge.confirmation_url
        end
      end

    end  
    
    def init_webhooks
      topics = ["app/uninstalled"]

      topics.each do |topic|
        #check if webbook exists
        hooks = ShopifyAPI::Webhook.find(:all, params => {:topic => topic})
        
        if hooks.size > 0
          hooks[0].destrory()
        end
        Rails.logger.debug("+++++ adding webhook" + "http://#{DOMAIN_NAMES[Rails.env]}/webhooks/#{topic}")
        webhook = ShopifyAPI::Webhook.create(:format => "json", :topic => topic, :address => "http://#{DOMAIN_NAMES[Rails.env]}/webhooks/#{topic}")
        raise "======Webhook invalid: #{webhook.errors.to_s}" unless webhook.valid?
      end
    end

      # return the version of theme currently deployed
    def current_deployed_version
      5
    end

end
