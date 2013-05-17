module Carriers
  module LifemapScience
    class Service < ::Carriers::RufusService
    end
  end
end

=begin
  in:Purchase Type
  ${r:Set['Media Kit'].superset?(${product_types_set})
  ${r:Set['Cells'].superset?(${product_types_set})
  ${r:Set['Basal Medium'].superset?(${product_types_set})
  ${r:Set['Media Kit', 'Cells'].superset?(${product_types_set})
=end