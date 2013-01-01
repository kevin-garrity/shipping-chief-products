class AustraliaPostApiConnection
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  attr_accessor :height, :length, :weight, :width
  attr_accessor :country_code, :air_mail_price, :sea_mail_price
  attr_accessor :domestic, :postcode, :regular_price, :priority_price, :express_price

  class << self
    def attr_accessor(*vars)
      @attributes ||= []
      @attributes.concat( vars )
      super
    end

    def attributes
      @attributes
    end

    def find(id)
      self.new(height: 1, weight: 1)
    end

    def all
      return []
    end

    def inspect
      "#<#{ self.to_s} #{ self.attributes.collect{ |e| ":#{ e }" }.join(', ') }>"
    end
  end

  def initialize(attributes={})
    @logger = Logger.new(STDOUT)

    attributes && attributes.each do |name, value|
      send("#{name}=", value) if respond_to? name.to_sym 
    end
  end

  def persisted?
    false
  end

  def data_oriented_methods(method)
    # routing for data oriented API

    case method
    when :country then self.country_list
    else raise "unknown data_oriented_method"
    end
  end

  def country_list
    @countries = HTTParty.get('https://auspost.com.au/api/postage/country.json', :headers => { 'auth-key' => credentials['api-key']}).flatten
    @logger.debug @countries[1]['country']

    @countries
  end

  def credentials
    @credentials ||= YAML.load_file("#{Rails.root}/config/australia_post_api.yaml")
  end

end
