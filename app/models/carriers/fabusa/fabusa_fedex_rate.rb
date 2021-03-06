module Carriers
  module Fabusa
    
require 'active_shipping'

class FabusaFedexRate

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

    #foldabox accoount
    fedex = ActiveMerchant::Shipping::FedEx.new(:login=>"104912167", :password =>"rZvWzz9UKKC4ugVdPX1iLkJ90", :account=>"277964333", :key =>"ns3hABMGvoAxjJrN")

    response = fedex.find_rates(origin, destination, packages)
    
    rates = response.rates
    
   # rates = response.rates.select do |rate|
  #    service_name = rate.service_name
  ##    service_name == "FedEx Ground"|| service_name == "FedEx Ground Home Delivery"||  service_name == "FedEx Standard Overnight" || service_name == "FedEx 2 Day"|| service_name == "FedEx 3 Day"
  #  end
      
    rates = rates.sort_by(&:price).collect do |rate|
        {"service_name" => rate.service_name, 'service_code'=> rate.service_name, 'total_price' => rate.price.to_i, 'currency' => rate.currency}
    end

    rates
  end


end


end
end
