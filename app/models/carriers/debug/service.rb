module Carriers
  module Debug
    class Service < ::Carriers::Service
      def fetch_rates
        ppl params
      end
    end
  end
end
