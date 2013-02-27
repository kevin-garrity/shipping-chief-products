# Read about factories at https://github.com/thoughtbot/factory_girl

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
    shipping_methods_allowed_dom {}
    shipping_methods_allowed_int {}
    shipping_methods_desc_int {}
    shipping_methods_desc_dom {}
  end
end

