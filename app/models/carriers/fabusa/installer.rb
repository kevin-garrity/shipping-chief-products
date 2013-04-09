module Carriers
  module Fabusa
    class Installer < ::Carriers::Installer
      
      def install
        register_custom_shipping_service
      end

    end
  end
end
