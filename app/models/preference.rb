class Preference < ActiveRecord::Base
  set_table_name 'preference'
  attr_accessible :origin_postal_code, :default_weight, :surchange_percentage, :height, :width, :length, :items_per_box, :default_charge, :shipping_methods_allowed_dom,
  :shipping_methods_allowed_int, :container_weight
  serialize   :shipping_methods_allowed_int, Hash
  serialize   :shipping_methods_allowed_dom, Hash
  
  validates :origin_postal_code, :length => { :is => 4 }
  validates :origin_postal_code, :numericality  => { :only_integer => true }  
  validates :surchange_percentage, :numericality => {:greater_than_or_equal_to => 0 }
  validates :items_per_box, :numericality =>  { :only_integer => true }  
  validates :default_weight, numericality: { greater_than: 0, less_than_or_equal_to: 20 }
  validates :default_charge, :numericality => true  
  
  validates :length, numericality: { greater_than_or_equal_to: 16, less_than_or_equal_to: 105 }
  validates :height, numericality: {  greater_than_or_equal_to: 16 }
  validates :width,  numericality: {  greater_than_or_equal_to: 16 }
  
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
         :AUS_PARCEL_PLATINUM => "Express Post Platinum Parcel"
        }
    end   
  
end