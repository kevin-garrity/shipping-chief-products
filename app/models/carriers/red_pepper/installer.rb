module Carriers
  module RedPepper
    class Installer < ::Carriers::Installer
      def configure
        Rails.logger.info("#{self.class.name}#configure")
      end
      def install
        Rails.logger.info("#{self.class.name}#install")
      end      
    end    
  end
end
