module Carriers
  module Purolator
    class Service < ::Carriers::Service
       
      def fetch_rates        
        purolator = PurolatorWrapper.new
    
        Rails.logger.debug("#{self.class.name}#fetch_rates")
        list = purolator.get_rates(self.origin, self.destination, items)
      
        return list
      end

    end    
  end
end
