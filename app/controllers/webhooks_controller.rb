class WebhookController < ApplicationController

  before_filter :verify_webhook, :except => 'verify_webhook'

  def uninstall_app
    data = ActiveSupport::JSON.decode(request.body.read)
    if Product.where('shopify_id = ?', data["id"]).first.exists?
      event = WebhookEvent.new(:event_type => "product new")
      event.save
      product = Product.new(:name => data["title"], :shopify_id => data["id"])
      product.webhook_events << event
      product.save
    end
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