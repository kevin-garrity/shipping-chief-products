module Carriers
  module LifemapScience
    class Service < ::Carriers::RufusService
      def process_decision_order!
        pkg_qty = 0
        decision_items.each do |item|
          pkg_qty += item['quantity'] unless Set["Human Embryonic Stem Cell", "Human Embryonic Progenitor"].include?(item['product_type'])
        end
        decision_order['pkg_qty'] = pkg_qty
      end
    end
  end
end

