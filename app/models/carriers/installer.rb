module Carriers
  class Installer
    attr_accessor :shop, :preference
    attr_accessor :port
    def initialize(shop, preference)
      @shop = shop
      @preference = preference
    end

    def port
      @port || "3000"
    end

    def configure
      # implement in subclasses
    end

    def install
      # implement in subclasses
    end

    def register_custom_shipping_service
      Rails.logger.info("register_custom_shipping_service")
      url = preference.shop_url
      
      #set up carrier services
      services = []

      case Rails.env
      when "production"
        params = {
          "name" => "Webify Custom Shipping Service",
          "callback_url" => "http://foldaboxusa.herokuapp.com/shipping-rates?shop_url="+ url,
          "service_discovery" => false,
          "format" => "json"
        }
        services = ShopifyAPI::CarrierService.find(:all, params => {:"name"=>"Webify Custom Shipping Service"})
      when "development" 
          my_ip = Webify::Dev.get_ip
           params = {
            "name" => "Webify Custom Shipping Service Development",
            "callback_url" => "http://#{my_ip}:#{port}/shipping-rates?shop_url="+ url,
            "service_discovery" => false,
            "format" => "json"
          } 
          services = ShopifyAPI::CarrierService.find(:all, params => {:"name"=>"Webify Custom Shipping Service Development"})
        else
          params = {
              "name" => "Webify Custom Shipping Service Staging",
              "callback_url" => "http://shipping-staging.herokuapp.com/shipping-rates?shop_url="+ url,
              "service_discovery" => false,
              "format" => "json"
            }     
          services = ShopifyAPI::CarrierService.find(:all, params => {:"name"=>"Webify Custom Shipping Service Development"})

      end


      #ShopifyAPI::CarrierService.delete(s[0].id)

      if (services.length == 0)
        carrier_service = ShopifyAPI::CarrierService.create(params)
        Rails.logger.debug("Error is " + carrier_service.errors.to_s) if carrier_service.errors.size > 0
      else
   
        ShopifyAPI::CarrierService.delete(services[0].id)
        carrier_service = ShopifyAPI::CarrierService.create(params)
        Rails.logger.debug("Readding Error is " + carrier_service.errors.to_s) if carrier_service.errors.size > 0
      end

      Rails.logger.info("Installed CarrierService: #{carrier_service.inspect}")
    end


  end
end