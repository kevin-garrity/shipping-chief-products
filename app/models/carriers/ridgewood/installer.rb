module Carriers
  module Ridgewood
    class Installer < ::Carriers::Installer
      def configure(params=nil)
        Rails.logger.info("#{self.class.name}#configure")
      end

      def install
        Rails.logger.info("#{self.class.name}#install")
        register_custom_shipping_service
      end      
    end    
  end
end
