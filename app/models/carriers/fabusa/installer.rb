module Carriers
  module Fabusa
    class Installer < ::Carriers::Installer
      
      def install
        register_custom_shipping_service
      end

      def register_custom_shipping_service

        Rails.logger.info("register_custom_shipping_service")
        url = shop.domain
        
        #set up carrier services
        
        if (Rails.env == "production")
          params = {
            "name" => "Webify Custom Shipping Service",
            "callback_url" => "http://foldaboxusa.herokuapp.com/shipping-rates?shop_url="+ url,
            "service_discovery" => false,
            "format" => "json"
          }
        else 
            params = {
              "name" => "Webify Custom Shipping Service Staging",
              "callback_url" => "http://shipping-staging.herokuapp.com/shipping-rates?shop_url="+ url,
              "service_discovery" => false,
              "format" => "json"
            }     
          
        end

        services = ShopifyAPI::CarrierService.find(:all, params => {:"name"=>"Webify Custom Shipping Service"})
        #ShopifyAPI::CarrierService.delete(s[0].id)

        if (services.length == 0)
          carrier_service = ShopifyAPI::CarrierService.create(params)
          logger.debug("Error is " + carrier_service.errors.to_s) if carrier_service.errors.size > 0
        else
     
          ShopifyAPI::CarrierService.delete(services[0].id)
          carrier_service = ShopifyAPI::CarrierService.create(params)
          logger.debug("Readding Error is " + carrier_service.errors.to_s) if carrier_service.errors.size > 0
        end

      end

    end    
  end
end
