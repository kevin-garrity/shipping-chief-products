module Carriers
  module Fabusa

require 'active_shipping'

class FabusaUpsRate

  attr_accessor :origin, :destination, :packages

  class InvalidError < StandardError
  end

  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  def initialize(attributes={}) 
    attributes && attributes.each do |name, value|
      send("#{name}=", value) if respond_to? name.to_sym
    end
  end

  def get_rates(origin, destination, packages)
    # :key is your developer API key
    # :password is your API password
    # :account is your FedEx account number
    # :login is your meter number

    ups = ActiveMerchant::Shipping::UPS.new(:login => 'foldaboxusa', :password => 'Nile1922', :key => '9CB1FB9E94E8C95A')
    response = ups.find_rates(origin, destination, packages)
    
    rates = response.rates
    
    rates = rates.sort_by(&:price).collect do |rate|
        {"service_name" => rate.service_name, 'service_code'=> 'NA', 'total_price' => rate.price.to_i, 'currency' => rate.currency}
    end   

    rates
  end


end

end
end
