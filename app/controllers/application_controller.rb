class ApplicationController < ActionController::Base
  protect_from_forgery
  
  private
    def check_payment


      if (Rails.env == "production")
       # unless (ShopifyAPI::RecurringApplicationCharge.current)
            #place a recurring charge
      #    charge = ShopifyAPI::RecurringApplicationCharge.create(:name => "Foldabox USA Private App", 
      ##                                                       :price => 15, 
      #                                                       :test=>(Rails.env != "production"),
      #                                                       :trial_days => 30,
      #                                                       :return_url => "http://#{DOMAIN_NAMES[Rails.env]}/confirm_charge")

      #    redirect_to charge.confirmation_url
      #  end
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
        logger.debug("+++++ adding webhook" + "http://#{DOMAIN_NAMES[Rails.env]}/webhooks/#{topic}")
        webhook = ShopifyAPI::Webhook.create(:format => "json", :topic => topic, :address => "http://#{DOMAIN_NAMES[Rails.env]}/webhooks/#{topic}")
        raise "======Webhook invalid: #{webhook.errors.to_s}" unless webhook.valid?
      end
    end

      # return the version of theme currently deployed
    def current_deployed_version
      3
    end

end
