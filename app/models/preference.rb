class Preference < ActiveRecord::Base
  set_table_name 'preference'
  attr_accessible :origin_postal_code, :default_weight, :surchange_percentage, :height, :width, :depth, :items_per_box
  
  validates :origin_postal_code, :length => { :is => 4 }
  validates :origin_postal_code, :numericality  => { :only_integer => true }  
  validates :surchange_percentage, :numericality => {:greater_than_or_equal_to => 0 }
  validates :items_per_box, :numericality =>  { :only_integer => true }  
  validates :default_weight, :numericality => true
  validates :height, :numericality => true
  validates :width, :numericality => true
  validates :depth, :numericality => true      
end