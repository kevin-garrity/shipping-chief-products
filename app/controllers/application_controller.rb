class ApplicationController < ActionController::Base
  protect_from_forgery
  
  private
    def check_payment

      unless ShopifyAPI::RecurringApplicationCharge.current
          #place a recurring charge
        charge = ShopifyAPI::RecurringApplicationCharge.create(:name => "Australia Post Shipping", 
                                                           :price => 15, :test=>true,
                                                           :return_url => "http://#{DOMAIN_NAMES[Rails.env]}/confirm_charge")

        redirect_to charge.confirmation_url
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
        webhook = ShopifyAPI::Webhook.create(:format => "json", :topic => topic, :address => "http://#{DOMAIN_NAMES[Rails.env]}/webhooks/#{topic}")
        raise "#{###}Webhook invalid: #{webhook.errors.to_s}" unless webhook.valid?
      end
    end    
end
