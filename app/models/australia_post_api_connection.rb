class AustraliaPostApiConnection
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  attr_accessor :height, :length, :weight, :width
  attr_accessor :country_code, :air_mail_price, :sea_mail_price
  attr_accessor :domestic, :postcode, :regular_price, :priority_price, :express_price

  def self.attr_accessor(*vars)
    @attributes ||= []
    @attributes.concat( vars )
    super
  end

  def self.attributes
    @attributes
  end

  def self.find(id)
    self.new(height: 1, weight: 1)
  end

  def self.all
    return []
  end

  def initialize(attributes={})
    attributes && attributes.each do |name, value|
      send("#{name}=", value) if respond_to? name.to_sym 
    end
  end

  def persisted?
    false
  end

  def self.inspect
    "#<#{ self.to_s} #{ self.attributes.collect{ |e| ":#{ e }" }.join(', ') }>"
  end

end
