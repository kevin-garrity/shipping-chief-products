# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :australia_post_api_connection do
    domestic false
    height 1
    weight 1
    length 1
    width 1
    country_code "MyString"
    from_postcode 1
    to_postcode 1
    air_mail_price 1.5
    sea_mail_price 1.5
    regular_price 1.5
    priority_price 1.5
    express_price 1.5
  end
end
