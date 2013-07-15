module Carriers
  module AusPostBus
    class Installer < ::Carriers::Installer
      def configure(params)
          @preference.shipping_methods_allowed_int = params[:shipping_methods_int]
          @preference.shipping_methods_allowed_dom = params[:shipping_methods_dom]
          @preference.shipping_methods_desc_dom = params[:shipping_methods_desc_dom]
          @preference.shipping_methods_desc_int = params[:shipping_methods_desc_int]
      end

      def install
        register_custom_shipping_service        
      end

    end
  end
end
