class SessionsController < ApplicationController
  def new
    authenticate if params[:shop].present?
  end

  def create
    authenticate
  end
  
  def show
    if response = request.env['omniauth.auth']
      sess = ShopifyAPI::Session.new(params[:shop], response['credentials']['token'])
      
     shop = Shop.find_by_url(params[:shop])
      if shop.nil?
        shop = Shop.new
        shop.url = params[:shop]
        shop.token = sess.token
        shop.save!
      else
        #update token
        shop.token = sess.token
        shop.save!        
      end
              
      session[:shopify] = sess        

      flash[:notice] = "Logged in"
      redirect_to return_address
    else
      flash[:error] = "Could not log in to Shopify store."
      redirect_to :action => 'new'
    end
  end
  
  def destroy
    session[:shopify] = nil
    flash[:notice] = "Successfully logged out."
    
    redirect_to :action => 'new'
  end
  
  protected
  
  def authenticate
    shop_name = sanitize_shop_param(params)
    #looking shop name and see if token is present
    if ShopifyAPI::Session.validate_signature(params)
      shop = Shop.find_by_url(shop_name)
    end
    unless shop.nil?
      #check signature
      #try to log in
      
      sess = ShopifyAPI::Session.new(shop_name, shop.token, params)      
    
      if sess.valid?
        ShopifyAPI::Base.activate_session(sess)        
        session[:shopify] = sess        
        flash[:notice] = "Logged in"
        redirect_to return_address
        return
      end
    end
      
    if shop_name
      redirect_to "/auth/shopify?shop=#{shop_name}"
    else
      redirect_to return_address
    end
  end
  
  def return_address
    session[:return_to] || root_url
  end
  
  def sanitize_shop_param(params)
    return unless params[:shop].present?
    name = params[:shop].to_s.strip
    name += '.myshopify.com' if !name.include?("myshopify.com") && !name.include?(".")
    name.sub('https://', '').sub('http://', '')
  end
end
