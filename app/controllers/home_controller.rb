class HomeController < ApplicationController
  
  around_filter :shopify_session, :except => 'welcome'
  before_filter :check_payment,:except => 'confirm_charge'
  
  def welcome
    current_host = "#{request.host}#{':' + request.port.to_s if request.port != 80}"
    @callback_url = "http://#{current_host}/login"
  end
  
  def index
    redirect_to preferences_path()
  end

  def confirm_charge
    # the old method of checking for params[:accepted] is deprecated.
    puts("params is" + params.to_s)
    charge = ShopifyAPI::RecurringApplicationCharge.find(params[:charge_id])
    puts("charge is" + charge.status.to_s)
    
    if (charge.status == 'accepted')
      charge.activate
      # update local data store
      url = session[:shopify].url
      shop = Shop.find_by_url(url)
      shop.active_subscriber = true
      shop.signup_date = DateTime.now
      shop.charge_id = params[:charge_id]
      shop.save()    

      begin
        init_webhooks
      rescue Exception=>e
        puts("Exception:" + e.to_s)
      end
      flash[:notice] = "Thank you for signing up! You are ready to go."
      redirect_to preferences_path()
    else
      flash[:notice] = "This is a paid application and you must agree to the payment term to use it"
      redirect_to "/login"
          
    end

  end



end