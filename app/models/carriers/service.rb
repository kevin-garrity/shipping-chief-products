require 'active_shipping'
# TODO: I really dislike including things in the global namespace. Then I have to go look up the code and make sure this is just a module with classes and isn't defining random methods that might mysteriously with my own
include ActiveMerchant::Shipping

module Carriers
  class Service
    attr_accessor :params

    def initialize(params)
      @params = params
    end

    def origin
      @origin ||= Location.new(params[:origin])
    end

    def destination
      @destination ||= Location.new(params[:destination])
    end

    def items
      params[:items]
    end

    def fetch_rates
      #  implement in subclasses
    end

  end
end