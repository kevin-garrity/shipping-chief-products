module Carriers
  class Installer
    attr_accessor :shop, :preference
    def initialize(shop, preference)
      @shop = shop
      @preference = preference
    end

    def configure
      # implement in subclasses
    end

    def install
      # implement in subclasses
    end
  end
end