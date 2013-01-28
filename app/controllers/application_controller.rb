class ApplicationController < ActionController::Base
  protect_from_forgery
  
  private
    def check_payment
      url = session[:shopify].url

      unless ShopifyAPI::RecurringApplicationCharge.current
          #place a recurring charge
        charge = ShopifyAPI::RecurringApplicationCharge.create(:name => "Australia Post Shipping", 
                                                           :price => 15, :test=>true,
                                                           :return_url => "http://localhost:3000/confirm_charge")

        redirect_to charge.confirmation_url
      end
    end  
end
