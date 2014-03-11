class Preference < ActiveRecord::Base
  class UnknownShopError < StandardError; end

  self.table_name = 'preference'
  attr_accessible :origin_postal_code, :default_weight, :surcharge_percentage, :surcharge_amount, :height, :width, :length, :items_per_box, :default_charge, :shipping_methods_allowed_dom, :default_box_size,
    :shipping_methods_allowed_int, :container_weight, :shipping_methods_desc_int, :shipping_methods_desc_dom, :shop_url, :carrier, :free_shipping_option, :free_shipping_description, :offers_flat_rate, :under_weight, :flat_rate,:free_shipping_by_collection
  serialize   :shipping_methods_allowed_int, Hash
  serialize   :shipping_methods_allowed_dom, Hash
  serialize   :shipping_methods_desc_int, Hash
  serialize   :shipping_methods_desc_dom, Hash

  validates :origin_postal_code, :length => { :is => 4 }, :unless => :shopify_pro_shop
  validates :origin_postal_code, :numericality  => { :only_integer => true }, :unless => :shopify_pro_shop
  validates :surcharge_percentage, :numericality => {:greater_than_or_equal_to => 0 }, :unless => :shopify_pro_shop

  validates :free_shipping_description, :length => { :minimum => 1 } , :allow_nil=>true, :unless =>  Proc.new { |a| !a.free_shipping_option }

  validates :under_weight, numericality: { greater_than_or_equal_to: 0.01 }, :unless => Proc.new { |a| !a.offers_flat_rate }
  validates :flat_rate, numericality: { greater_than_or_equal_to: 0.01 }, :unless => Proc.new { |a| !a.offers_flat_rate }


  validates :default_weight, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 20 }, :unless => :shopify_pro_shop
  validates :default_charge, :numericality => true, :allow_nil => true, :unless => :shopify_pro_shop
  validates :surcharge_amount, :numericality => true, :allow_nil => true, :unless => :shopify_pro_shop
  

  validates :length, numericality: { greater_than_or_equal_to: 14, less_than_or_equal_to: 105 }, :unless => :shopify_pro_shop
  validates :height, :numericality => true, :unless => :shopify_pro_shop
  validates :width,  numericality: {  greater_than_or_equal_to: 12 }, :unless => :shopify_pro_shop
  
  validate :no_surcharge_percentage_and_amount, :unless => :shopify_pro_shop

  def self.find_by_shop(shop)
    preference = Preference.arel_table
    
    domain = shop.domain || ""
    myshopify_domain = shop.myshopify_domain || ""
    
    Preference.where(
      preference[:shop_url].eq( domain ).
      or(
      preference[:shop_url].eq( myshopify_domain ))
    ).first
  end

  def self.find_by_shop_url(url)
    preference = Preference.arel_table
    
    domain = url
    domain2 = url.sub("www.", "") if url.include?("www.")
    domain2 = "www." + url unless url.include?("www.")
       
    Preference.where(
      preference[:shop_url].eq( domain ).
      or(
      preference[:shop_url].eq( domain2))
    ).first
  end
  
  def self.AusPostParcelServiceListInt
    {:INTL_SERVICE_ECI_M =>"Express Courier International Merchandise",
      :INTL_SERVICE_ECI_D => "Express Courier International Documents",
      :INTL_SERVICE_EPI => "Express Post International",
      :INTL_SERVICE_AIR_MAIL => "Air Mail",
      :INTL_SERVICE_SEA_MAIL => "Sea Mail"}
  end

  def self.AusPostParcelServiceListDom
    {:AUS_PARCEL_REGULAR =>"Regular Parcel",
      :AUS_PARCEL_EXPRESS => "Express Post Parcel",
      :AUS_PARCEL_PLATINUM => "Express Post Platinum Parcel",
      :AUS_PARCEL_REGULAR_SATCHEL_500G => "Prepaid Parcel Post Plus 500g Satchel",
      :AUS_PARCEL_EXPRESS_SATCHEL_500G => "Express Post 500g Satchel",
      :US_PARCEL_PLATINUM_SATCHEL_500G => "Express Post Platinum 500g Satchel",
      :AUS_PARCEL_REGULAR_SATCHEL_3KG => "Prepaid Parcel Post Plus 3kg Satchel",
      :AUS_PARCEL_EXPRESS_SATCHEL_3KG => "Express Post 3kg Satchel",
      :US_PARCEL_PLATINUM_SATCHEL_3KG => "Express Post Platinum 3kg Satchel",
      :AUS_PARCEL_REGULAR_SATCHEL_5KG => "Prepaid Parcel Post Plus 5kg Satchel",
      :AUS_PARCEL_EXPRESS_SATCHEL_5KG => "Express Post 5kg Satchel",
      :US_PARCEL_PLATINUM_SATCHEL_5KG => "Express Post Platinum 5kg Satchel"
    }
  end

  def shopify_pro_shop
    carrier != 'AusPost'
  end
  
  def no_surcharge_percentage_and_amount
    if (surcharge_percentage > 0.0 && surcharge_amount > 0.0)
      errors.add(:surcharge_percentage, "cannot be non-zero when there is surcharge amount.")
    end
  end

  def client_config
    config = AppConfig.clients[shop_url]
    
    #load default if none can be found
    config = AppConfig.clients["default"] if config.nil?
    config
  end
  
end
