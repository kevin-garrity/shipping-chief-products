class SessionsController < ApplicationController
  before_filter :logging

  def new
    authenticate if params[:shop].present?
  end

  def create
    authenticate
  end
  
  def show
    if response = request.env['omniauth.auth']
      token = response['credentials']['token']
      sess = ShopifyAPI::Session.new(params[:shop], token)
      ShopifyAPI::Base.activate_session(sess) 
      
      shop = Shop.find_by_url(params[:shop])
      if shop.nil?
        puts("@@@@@@ creating shop")
        puts("@@@@@@ params[:shop] is " + params[:shop].to_s)  
        shop = Shop.new
        
        shopify_api_shop = ShopifyAPI::Shop.current
        
        shop.myshopify_domain = params[:shop]
        shop.domain = shopify_api_shop.domain
        
        shop.token = sess.token
        shop.version = current_deployed_version
        shop.save!
      else
        #update token
        shop.token = sess.token
        shop.save!
      end
              
      session[:shopify] = sess        

      flash[:notice] = "Logged in"
      Rails.logger.info("redirect to #{return_address}")
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
      @shop = Shop.find_by_url(shop_name)
    end
    unless @shop.nil?
      #check signature
      #try to log in
      
      sess = ShopifyAPI::Session.new(shop_name, @shop.token, params)      
    
      init_webhooks

      if sess.valid?
        ShopifyAPI::Base.activate_session(sess) 
        shopify_api_shop = ShopifyAPI::Shop.current
        @shop.update_attributes(
          domain: shopify_api_shop.domain,
          myshopify_domain: shopify_api_shop.myshopify_domain
        )
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

  def logging
      Rails.logger.debug("request.headers['HTTP_X_SHOPIFY_SHOP_DOMAIN']: #{request.headers['HTTP_X_SHOPIFY_SHOP_DOMAIN'].inspect}") if Rails.env.development?
  end
  
end
