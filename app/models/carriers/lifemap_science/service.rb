module Carriers
  module LifemapScience
    class Service < ::Carriers::RufusService

      # def variant_metafields
      #   [
      #     { namespace: 'wby.ship', key: 'refrigeration' }
      #   ]
      # end

      # def process_decision_order!
      #   pkg_qty = 0
      #   decision_items.each do |item|
      #     pkg_qty += item['quantity'] unless Set["Human Embryonic Stem Cell", "Human Embryonic Progenitor"].include?(item['product_type'])
      #   end
      #   decision_order['pkg_qty'] = pkg_qty
      # end
    end
  end
end

=begin
 processing item decisions
 1. pass each item through all the item decions
 2. if they are set to accumulate you may get multiple values
 3. After running ALL the items, collapse the set of values by [service_name_column]
 4. When there are values, collapse them by the following rules:
    sum:blah --> add them
    max:blah --> take the max
    min:blah --> take the min
    prod:blah -> take their product
    and:blah -> convert to boolean & do and
    or:blah ->  convert to boolean and do or
    blah -> convert to rudelo set

    NOTE: 
    order decisions multiply
    item decisions don't
    multiplying decisions can always be accomplished by multiplying within a single table. If we have an item decision for which this becomes onerous we can look at optionally having item decisions multiply.


=end