class ApplicationController < ActionController::Base
  protect_from_forgery
  
  private
    def check_payment

      
    end  
    
    def init_webhooks
      topics = ["app/uninstalled"]

      topics.each do |topic|
        #check if webbook exists
        hooks = ShopifyAPI::Webhook.find(:all, params => {:topic => topic})
        
        if hooks.size > 0
          hooks[0].destrory()
        end
        puts("+++++ adding webhook" + "http://#{DOMAIN_NAMES[Rails.env]}/webhooks/#{topic}")
        webhook = ShopifyAPI::Webhook.create(:format => "json", :topic => topic, :address => "http://#{DOMAIN_NAMES[Rails.env]}/webhooks/#{topic}")
        raise "======Webhook invalid: #{webhook.errors.to_s}" unless webhook.valid?
      end
    end    
end
