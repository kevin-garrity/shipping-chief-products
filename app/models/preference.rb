class Preference < ActiveRecord::Base
  class UnknownShopError < StandardError; end

  set_table_name 'preference'
  attr_accessible :origin_postal_code, :default_weight, :surchange_percentage, :surchange_amount, :height, :width, :length, :items_per_box, :default_charge, :shipping_methods_allowed_dom, :default_box_size,
    :shipping_methods_allowed_int, :container_weight, :shipping_methods_desc_int, :shipping_methods_desc_dom
  serialize   :shipping_methods_allowed_int, Hash
  serialize   :shipping_methods_allowed_dom, Hash
  serialize   :shipping_methods_desc_int, Hash
  serialize   :shipping_methods_desc_dom, Hash

  validates :origin_postal_code, :length => { :is => 4 }
  validates :origin_postal_code, :numericality  => { :only_integer => true }
  validates :surchange_percentage, :numericality => {:greater_than_or_equal_to => 0 }

  validates :default_weight, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 20 }
  validates :default_charge, :numericality => true, :allow_nil => true
  validates :surchange_amount, :numericality => true, :allow_nil => true
  

  validates :length, numericality: { greater_than_or_equal_to: 14, less_than_or_equal_to: 105 }
  validates :height, :numericality => true
  validates :width,  numericality: {  greater_than_or_equal_to: 12 }
  
  validate :no_surcharge_percentage_and_amount

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

  def self.method_missing(name, *args, &block)
    results = super(name, *args, &block)
    if name.to_s != "find_by_shop_url" && results.nil?
      # if the results are completely empty, we can't proceed
      raise UnknownShopError.new("Shipping Calculator has not been configured.")
    else
    end

    return results
  end
  
  def no_surcharge_percentage_and_amount
    if (surchange_percentage > 0.0 && surchange_amount > 0.0)
      errors.add(:surchange_percentage, "cannot be non-zero when there is surcharge amount.")
    end
  end

end
