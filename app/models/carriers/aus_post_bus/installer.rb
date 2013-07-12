module Carriers
  module AusPostBus
    class Installer < ::Carriers::Installer
      def configure(params)

      end

      def install
        register_custom_shipping_service        
      end

    end
  end
end
