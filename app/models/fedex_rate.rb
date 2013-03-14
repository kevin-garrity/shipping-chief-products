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
  
  def get_rates()
    # :key is your developer API key
    # :password is your API password
    # :account is your FedEx account number
    # :login is your meter number
    
    fedex = FedEx.new(:login=>"", :password =>"", :account=>"", :key =>"")
    response = fedex.find_rates(origin, destination, packages)
    rates = response.rates.sort_by(&:price).collect {|rate| [rate.service_name, rate.price]}
  end
  
  
end