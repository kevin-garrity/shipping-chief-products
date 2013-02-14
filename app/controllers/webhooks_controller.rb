class WebhooksController < ActionController::Base

  before_filter :verify_webhook, :except => 'verify_webhook'

  def uninstall_app
    
    data = ActiveSupport::JSON.decode(request.body.read)
    puts ("$$$$ data is " + data.to_s)
    
    shop_url = data["domain"]
    puts ("$$$$ shop url is " + shop_url) unless shop_url.nil?
    #look for shop record
    shop = Shop.find_by_url(shop_url)
    puts ("$$$$ shop being destroy")
    
    begin
      shop.destory unless shop.nil?
    rescue Exception=>e
      puts ("$$$$ exception destroying" + e.to_s)
    end
    puts ("$$$$ shop destroyed")
    head :ok
  end
  
  def verify_webhook
    data = request.body.read.to_s
    hmac_header = request.headers['HTTP_X_SHOPIFY_HMAC_SHA256']
    digest = OpenSSL::Digest::Digest.new('sha256')
    calculated_hmac = Base64.encode64(OpenSSL::HMAC.digest(digest, WorldShippingCalculator::Application.config.shopify.secret, data)).strip
    unless calculated_hmac == hmac_header
      head :unauthorized
    end
    request.body.rewind
  end
  
end