# Read about factories at https://github.com/thoughtbot/factory_girl

def self.AusPostParcelServiceListInt
end

FactoryGirl.define do
  factory :preference_for_shop, class: Preference do
    origin_postal_code 3222
    default_weight 2
    surcharge_percentage 5
    surcharge_amount 0
    shop_url "www.existingshop.com"
    height 16
    width 16
    length 16
    items_per_box 2
    default_charge 5
    container_weight 2
    default_box_size 10
    shipping_methods_allowed_int {{"INTL_SERVICE_ECI_M"=>"1", "INTL_SERVICE_ECI_D"=>"1", "INTL_SERVICE_EPI"=>"1", "INTL_SERVICE_AIR_MAIL"=>"1", "INTL_SERVICE_SEA_MAIL"=>"1"}}
    shipping_methods_allowed_dom {{"AUS_PARCEL_REGULAR"=>"1", "AUS_PARCEL_EXPRESS_SATCHEL_500G"=>"1", "US_PARCEL_PLATINUM_SATCHEL_500G"=>"1", "AUS_PARCEL_REGULAR_SATCHEL_3KG"=>"1", "AUS_PARCEL_EXPRESS_SATCHEL_3KG"=>"1", "US_PARCEL_PLATINUM_SATCHEL_3KG"=>"1", "AUS_PARCEL_REGULAR_SATCHEL_5KG"=>"1", "AUS_PARCEL_EXPRESS_SATCHEL_5KG"=>"1", "US_PARCEL_PLATINUM_SATCHEL_5KG"=>"1"}}
    carrier "fedex"

    shipping_methods_desc_int {}
    shipping_methods_desc_dom {}
  end
  
  factory :preference_for_fabusa_shop, class: Preference do
    origin_postal_code 3222
    default_weight 2
    surcharge_percentage 5
    surcharge_amount 0
    shop_url "www.foldaboxusa.com"
    height 16
    width 16
    length 16
    carrier "fabusa"
    items_per_box 2
    default_charge 5
    container_weight 2
    default_box_size 10
    shipping_methods_allowed_int {{"INTL_SERVICE_ECI_M"=>"1", "INTL_SERVICE_ECI_D"=>"1", "INTL_SERVICE_EPI"=>"1", "INTL_SERVICE_AIR_MAIL"=>"1", "INTL_SERVICE_SEA_MAIL"=>"1"}}
    shipping_methods_allowed_dom {{"AUS_PARCEL_REGULAR"=>"1", "AUS_PARCEL_EXPRESS_SATCHEL_500G"=>"1", "US_PARCEL_PLATINUM_SATCHEL_500G"=>"1", "AUS_PARCEL_REGULAR_SATCHEL_3KG"=>"1", "AUS_PARCEL_EXPRESS_SATCHEL_3KG"=>"1", "US_PARCEL_PLATINUM_SATCHEL_3KG"=>"1", "AUS_PARCEL_REGULAR_SATCHEL_5KG"=>"1", "AUS_PARCEL_EXPRESS_SATCHEL_5KG"=>"1", "US_PARCEL_PLATINUM_SATCHEL_5KG"=>"1"}}

    shipping_methods_desc_int {}
    shipping_methods_desc_dom {}
  end
  
end


