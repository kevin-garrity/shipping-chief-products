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

    def configure
      # implement in subclasses
    end

    def install
      # implement in subclasses
    end

    def service_host
      client_config.service_host || "foldaboxusa.herokuapp.com"
    end

    def service_url
      case Rails.env
      when "production", "staging"
        "http://#{service_host}/shipping-rates?shop_url=#{preference.shop_url}"
      when "development"
        my_ip = Webify::Dev.get_ip
        "http://#{my_ip}:#{port}/shipping-rates?shop_url=#{preference.shop_url}"
      end
    end

    def service_name
      case Rails.env
      when "production"
        client_config.service_name || "Webify Custom Shipping Service"
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

      services = ShopifyAPI::CarrierService.find(:all, params:
        {name: service_name})

      Rails.logger.info("destroying #{services.length} existing services")
      services.each{ |service| service.destroy }
      carrier_service = ShopifyAPI::CarrierService.create(params)
      if carrier_service.errors.size > 0
        Rails.logger.debug("Error creating CarrierService " + carrier_service.errors.to_s)
        Rails.logger.debug carrier_service.inspect
      else
        Rails.logger.info("Installed CarrierService: #{carrier_service.inspect}")
      end

    end


  end
end