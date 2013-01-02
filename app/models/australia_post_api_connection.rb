class AustraliaPostApiConnection
  class InvalidError < StandardError
  end

  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  attr_accessor :height, :length, :weight, :width
  attr_accessor :country_code, :air_mail_price, :sea_mail_price
  attr_accessor :domestic, :from_postcode, :to_postcode, :regular_price, :priority_price, :express_price

  class Girth < ActiveModel::Validator
    # implement the method where the validation logic must reside
    def validate(record)
      if options[:less_than_or_equal_to] && 2 * ( record.width.to_i + record.height.to_i ) > options[:less_than_or_equal_to]
        record.errors[:base] << "The dimensions exceed the maximum girth of #{options[:less_than_or_equal_to]}cm."
      end
    end
  end

  validates :from_postcode, presence: true
  validates :to_postcode, presence: true, :if => Proc.new {|record| record.domestic }

  validates :length, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 16, less_than_or_equal_to: 105 }
  validates :height, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 16 }
  validates :width, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 16 }

  validates_with Girth, { less_than_or_equal_to: 140 }

  validates :weight, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 20 }

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
    attributes && attributes.each do |name, value|
      send("#{name}=", value) if respond_to? name.to_sym 
    end
  end

  def persisted?
    false
  end

  def save(force=false)
    unless valid?
      raise InvalidError.new(errors.full_messages)
    end

    true
  end

  def data_oriented_methods(method)
    # routing for data oriented API

    case method
    when :country then self.country_list
    when :service then
      if self.domestic
        self.domestic_service_list
      else
        self.international_service_list
      end
    else raise "unknown data_oriented_method"
    end
  end

  def country_list
    @countries = HTTParty.get("#{self.api_root}/country.json",
                              :query => { }, # no params
                              :headers => { 'auth-key' => credentials['api-key']}).flatten
  end

  def domestic_service_list
    @service_list = HTTParty.get("#{self.api_root}/parcel/domestic/service.json", 
                                 :query => { from_postcode: self.from_postcode,
                                             to_postcode: self.to_postcode,
                                             length: self.length,
                                             width: self.width,
                                             height: self.height,
                                             weight: self.weight },
                                 :headers => { 'auth-key' => credentials['api-key']}).flatten
  end

  def international_service_list
    @service_list = HTTParty.get("#{self.api_root}/parcel/international/service.json", 
                                 :query => { from_postcode: self.from_postcode,
                                             to_postcode: self.to_postcode,
                                             length: self.length,
                                             width: self.width,
                                             height: self.height,
                                             weight: self.weight },
                                 :headers => { 'auth-key' => credentials['api-key']}).flatten
  end

  def credentials
    @credentials ||= YAML.load_file("#{Rails.root}/config/australia_post_api.yaml")
  end

  def api_root
    "https://auspost.com.au/api/postage"
  end

end
