require 'active_shipping'
include ActiveMerchant::Shipping

class FedexRate

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

    fedex = FedEx.new(:login=>"104912167", :password =>"rZvWzz9UKKC4ugVdPX1iLkJ90", :account=>"277964333", :key =>"ns3hABMGvoAxjJrN")
    response = fedex.find_rates(origin, destination, packages)
    rates = response.rates.sort_by(&:price).collect do |rate|
      {"service_name" => rate.service_name, 'service_code'=> 'NA', 'total_price' => rate.price.to_i, 'currency' => rate.currency}
    end

    rates
  end


end

