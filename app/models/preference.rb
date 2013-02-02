class Preference < ActiveRecord::Base
  set_table_name 'preference'
  attr_accessible :origin_postal_code, :default_weight, :surchange_percentage, :height, :width, :length, :items_per_box, :default_charge, :shipping_methods_allowed
  serialize   :shipping_methods_allowed, Hash
  
  validates :origin_postal_code, :length => { :is => 4 }
  validates :origin_postal_code, :numericality  => { :only_integer => true }  
  validates :surchange_percentage, :numericality => {:greater_than_or_equal_to => 0 }
  validates :items_per_box, :numericality =>  { :only_integer => true }  
  validates :default_weight, :numericality => true
  validates :default_charge, :numericality => true
  validates :height, :numericality => {:greater_than_or_equal_to => 16 }
  validates :width, :numericality => {:greater_than_or_equal_to => 16 }
  validates :length, :numericality => {:greater_than_or_equal_to => 16 }
  
  def self.AusPostParcelServiceList
      {:INTL_SERVICE_ECI_M =>"Express Courier International Merchandise", 
        :INTL_SERVICE_ECI_D => "Express Courier International Documents",
        :INTL_SERVICE_EPI => "Express Post International",
        :INTL_SERVICE_AIR_MAIL => "Air Mail",
        :INTL_SERVICE_SEA_MAIL => "Sea Mail"}
   end
   
  
end