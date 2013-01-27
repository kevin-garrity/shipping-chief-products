class Preference < ActiveRecord::Base
  set_table_name 'preference'
  attr_accessible :origin_postal_code, :default_weight, :surchange_percentage
  
  validates :origin_postal_code, :length => { :is => 4 }
  validates :origin_postal_code, :numericality  => { :only_integer => true }  
  validates :surchange_percentage, :numericality => true
  validates :default_weight, :numericality => true
  
end