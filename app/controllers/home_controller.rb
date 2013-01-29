class HomeController < ApplicationController
  
  around_filter :shopify_session, :except => 'welcome'
  before_filter :check_payment,:except => 'confirm_charge'
  
  def welcome
    current_host = "#{request.host}#{':' + request.port.to_s if request.port != 80}"
    @callback_url = "http://#{current_host}/login"
  end
  
  def index
    #check if user has paid or not
    redirect_to preferences_path()
  end

  def confirm_charge
    # the old method of checking for params[:accepted] is deprecated.
    ShopifyAPI::RecurringApplicationCharge.find(params[:charge_id]).activate
    

    # update local data store
    url = session[:shopify].url
    shop = Shop.find_by_url(url)
    shop.active_subscriber = true
    shop.signup_date = DateTime.now
    shop.save()
    
    flash[:notice] = "Thank you for signing up! You are ready to go."
    redirect_to preferences_path()
  end



end