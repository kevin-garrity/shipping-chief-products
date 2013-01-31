class AustraliaPostApiConnection
  class InvalidError < StandardError
  end

  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  attr_accessor :attributes, :api_errors

  attr_accessor :height, :length, :weight, :width, :blanks
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

  class ResponseErrors < ActiveModel::Validator
    # implement the method where the validation logic must reside
    def validate(record)
      if record.api_errors.length > 0
        record.errors[:base] << "The following errors were returned by the Australia Post API"

        record.api_errors.each do |error|
          record.errors[:base] << error
        end
      end
    end
  end

  validates :from_postcode, presence: true
  validates :to_postcode, presence: true, :if => Proc.new {|record| record.domestic }

  validates_with ResponseErrors

  validates :length, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 16, less_than_or_equal_to: 105 }
  validates :height, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 16 }
  validates :width, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 16 }
  validates_with Girth, { less_than_or_equal_to: 140 }

  # TODO we no longer need to validate weight, since we now accept larger packages 
  # validates :weight, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 20 }

  class << self
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

    self.api_errors = []
    self.attributes = attributes
  end

  def persisted?
    false
  end

  def save(force=false)
    unless valid?
      raise InvalidError.new(errors.full_messages)
    end

    valid = true
    unless self.api_errors.empty?
      valid = false
    end

    valid
  end

  def data_oriented_methods(method)
    # routing for data oriented API

    case method
    when :country then get_list_of_countries
    when :service then get_service_list
    else raise "unknown data_oriented_method"
    end
  end

  def get_list_of_countries
    api_call "country.json"
  end

  def get_service_list
    request_url = if self.domestic
                    "parcel/domestic/service.json"
                  else
                    "parcel/international/service.json"
                  end

    total_weight = self.attributes[:weight].to_i
    package_weight = 20
    number_of_packages = total_weight / package_weight
    excess_weight = total_weight % package_weight

    self.attributes[:weight] = package_weight
    result = api_call(request_url)

    unless self.api_errors
      result[1]["service"].each do |hash|
        # gsub so that we can work with integers
        original_price = hash["price"].to_s.gsub(/\./, "").to_i

        # gsub so that the price will be in dollars and cents yo
        modified_price = ( original_price * number_of_packages).to_s.gsub(/(.*)([0-9]{2}$)/) {$1 + "." + $2}

        hash["price"] = modified_price
      end

      if excess_weight > 0
        self.attributes[:weight] = excess_weight
        response = api_call(request_url)

        # we iterate with index so that we can compare the two response structures
        result[1]["service"].to_enum.with_index(0) do |hash, i|
          original_price = hash["price"].to_s.gsub(/\./, "").to_i
          excess_weight_price = response[1]["service"][i]["price"].to_s.gsub(/\./, "").to_i

          modified_price = ( original_price + excess_weight_price).to_s.gsub(/(.*)([0-9]{2}$)/) {$1 + "." + $2}

          hash["price"] = modified_price
        end
      end
    end

    # set the weight back to its original value
    self.attributes[:weight] = total_weight
    result
  end

  def api_call(method)

    command = Thread.new do
      Thread.current["httparty_response"] = HTTParty.get("#{self.api_root}/#{method}",
                                                           :query => self.attributes,
                                                           :timeout => 150, # sec
                                                           :headers => { 'auth-key' => credentials['api-key']})
    end

    command.join                 # main programm waiting for thread

    begin
      @service_list = command["httparty_response"].flatten

      if @service_list[0] == "error"
        self.api_errors.append(@service_list[1]['errorMessage'])
      end
    rescue
      raise "command in rescue " + command["httparty_response"].inspect
    end

    @service_list
  end

  def credentials
    @credentials ||= YAML.load_file("#{Rails.root}/config/australia_post_api.yaml")
  end

  def api_root
    "https://auspost.com.au/api/postage"
  end

end
