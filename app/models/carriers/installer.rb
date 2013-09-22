module Carriers
  class Installer
    attr_accessor :shop, :preference
    attr_accessor :port
    def initialize(shop, preference)
      @shop = shop
      @preference = preference
    end

    delegate :client_config, to: :preference

    def port
      @port || "3000"
    end

    def configure(params=nil)
      # implement in subclasses
    end
    
    def app_shop
      Shop.find_by_url(preference.shop_url)
    end
    

    def install
      # implement in subclasses
    end
    
    def withShopify
       ShopifyAPI::Session.temp(app_shop.myshopify_domain, app_shop.token) do
         yield
       end
     end

    def service_host
      client_config.service_host || "foldaboxusa.herokuapp.com"
    end

    def service_url
      case Rails.env
      when "production"
        "http://#{service_host}/shipping-rates?shop_url=#{preference.shop_url}"
      when "staging"      
        "http://shipping-staging.herokuapp.com/shipping-rates?shop_url=#{preference.shop_url}"          
      when "development"
        my_ip = Webify::Dev.get_ip
        "http://#{my_ip}:#{port}/shipping-rates?shop_url=#{preference.shop_url}"
      end
    end

    def service_name
      case Rails.env
      when "production"
         "Webify Custom Shipping Service"
      when "staging", "development"
        (client_config.service_name || "Webify Custom Shipping Service") + " " + Rails.env.capitalize
      end
    end

    def register_custom_shipping_service
      Rails.logger.info("register_custom_shipping_service")

      params = {
        name: service_name,
        callback_url: service_url,
        service_discovery: false,
        format: "json"
      }

      services = ShopifyAPI::CarrierService.find(:all)

      Rails.logger.info("destroying #{services.length} existing services")
      services.each{ |service| service.destroy }
      carrier_service = ShopifyAPI::CarrierService.create(params)
      if carrier_service.errors.size > 0
        Rails.logger.info("Error creating CarrierService " + carrier_service.errors.to_s)
        Rails.logger.info carrier_service.inspect
      else
        Rails.logger.info("Installed CarrierService: #{carrier_service.inspect}")
      end

    end


  end
end