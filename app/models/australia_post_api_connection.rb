
class AustraliaPostApiConnection
  class InvalidError < StandardError
  end

  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  attr_accessor :attributes, :api_errors

  attr_accessor :items, :height, :length, :weight, :width, :blanks,  :thickness #for letter mail
  attr_accessor :country_code, :air_mail_price, :sea_mail_price
  attr_accessor :domestic, :from_postcode, :to_postcode
  attr_accessor :regular_price, :priority_price, :express_price
  attr_accessor :container_weight
  attr_accessor :has_free_shipping_items

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

  validates :length, presence: true, numericality: { greater_than_or_equal_to: 14, less_than_or_equal_to: 105 }
  validates :height, presence: true, numericality: true
  validates :width, presence: true, numericality: {  greater_than_or_equal_to: 12 }
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
    # unless valid?
    #   raise InvalidError.new(errors.full_messages)
    # end

    Rails.logger.info("api_errors " + self.api_errors.inspect)
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

    # cases:
    #   total_weight < 20
    #     make 1 API call at total_weight
    #   total_weight = 20
    #     make 1 API call at total_weight
    #   total_weight > 20
    #     make 1 API call at max_weight and multiply the result
    #     make 1 API call at excess weight
    #
    
    total_weight = self.attributes[:weight].to_f
    
    #get total weight 

    # the max weight for a single AUS api call
    # the weight of the container
    # the difference
    api_max_weight = 20
    container_weight = self.attributes[:container_weight]
    container_weight = 0 if container_weight.nil?
    contents_weight = api_max_weight - container_weight

    if total_weight <= contents_weight
      # we can fit the cart into 1 API call
      number_of_packages = 1
      excess_weight = 0
    else
      # we will need to do an API call at the max weight,
      # and then multiply the resulting price
      # and then make 1 more call to get the excess (which fits in 1 container)
      number_of_packages = (total_weight / contents_weight).to_i
      excess_weight = total_weight % contents_weight
      excess_weight += container_weight if excess_weight > 0 # put it in a box
      self.attributes[:weight] = api_max_weight
    end

    Rails.logger.debug("total weight: " + total_weight.to_s)
    Rails.logger.debug("container_weight: " + container_weight.to_s)
    Rails.logger.debug("contents_weight: " + contents_weight.to_s)

    Rails.logger.debug("number_of_packages : " + number_of_packages.to_s)
    Rails.logger.debug("excess_weight : " + excess_weight.to_s)

    result = api_call(request_url)
    Rails.logger.debug("after performing 20 kg call")

    # modify the results so that they represent n packages + the excess
    if self.api_errors.empty?
      services = Array.wrap(result[1]["service"]) # sometimes the services are a plain hash

      # multiply the prices by the number of packages
      services.map do |hash|
        # gsub so that we can work with integers
        #Rails.logger.info("  service: \n " + hash.inspect)
        if hash.has_key?("price")

          original_price = hash["price"].to_f
          Rails.logger.debug("  original_price: " + original_price.to_s)
          modified_price = ( original_price * number_of_packages).to_f

          hash["price"] = modified_price
          hash
        end
      end

      Rails.logger.debug("after 20 package stuff -- \n\n" + services.inspect)

      if excess_weight > 0
        Rails.logger.debug("#{excess_weight.to_s} kg package")

        # set up a mini API call to determine the cost of shipping the excess
        self.attributes[:weight] = excess_weight
        response = api_call(request_url)

        response_services = Array.wrap(response[1]["service"]) # same reason as above
        #Rails.logger.info("  response_services: -- \n\n" + response_services.inspect)

        services.to_enum.with_index(0) do |hash, i|
          original_price = hash["price"].to_f
          excess_weight_price = response_services[i]["price"].to_f
          modified_price = original_price + excess_weight_price

          hash["price"] = modified_price.to_f
        end

      end

      result[1]["service"] = services
      Rails.logger.debug("finally -- \n\n\n" + result[1]["service"].inspect)
    end

    # set the weight back to its original value
    self.attributes[:weight] = total_weight
    result
  end

  def api_call(method)
    Thread.abort_on_exception = true

      command = Thread.new do
        begin
       
        Thread.current["httparty_response"] = HTTParty.get("#{self.api_root}/#{method}",
                                                             :query => self.attributes,
                                                             :timeout => 10, # sec
                                                             :headers => { 'auth-key' => credentials['api-key']})
        rescue Timeout::Error => e        
          self.api_errors.append("Sorry, we couldn't connect to Australia Post API. Try again in a moment.")
        rescue Exception => e
          # anything else
          self.api_errors.append(e)
          Rails.logger.debug("error: " + e.message)
          Rails.logger.debug("api connection will not be saved")
        end
      end

    command.join                 # main programm waiting for thread

    begin
      @service_list = command["httparty_response"].flatten

      if @service_list[0] == "error"
        self.api_errors.append(@service_list[1]['errorMessage'])
      end
    rescue NoMethodError => e
      Rails.logger.debug("error: " + e.message)
      # we actually already reported this
      # It refers to flatten above, and comes from
      # the Timeout::Error rescued above
      # So we'll not report it
    rescue Exception => e
      # anything else
      self.api_errors.append(e)
      Rails.logger.debug("error: " + e.message)
      Rails.logger.debug("api connection will not be saved")
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
