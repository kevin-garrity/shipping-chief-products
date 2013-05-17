module Carriers
  module Debug
    class Service < ::Carriers::Service
      def fetch_rates
        ppl params
      end
    end
  end
end

=begin
sample params sent by shopify:

{"rate"=>
  {"origin"=>
    {"country"=>"US",
     "postal_code"=>"49686",
     "province"=>"MI",
     "city"=>"Traverse City",
     "name"=>nil,
     "address1"=>"807 Airport Access Road",
     "address2"=>"",
     "address3"=>nil,
     "phone"=>nil,
     "fax"=>nil,
     "address_type"=>nil,
     "company_name"=>nil},
   "destination"=>
    {"country"=>"US",
     "postal_code"=>"35004",
     "province"=>"AL",
     "city"=>nil,
     "name"=>nil,
     "address1"=>nil,
     "address2"=>nil,
     "address3"=>nil,
     "phone"=>nil,
     "fax"=>nil,
     "address_type"=>nil,
     "company_name"=>nil},
   "items"=>
    [{"name"=>"RatesDebug - High / High / High",
      "sku"=>"samesku",
      "quantity"=>2,
      "grams"=>1000,
      "price"=>100000,
      "vendor"=>"LastObelus",
      "requires_shipping"=>true,
      "taxable"=>true,
      "fulfillment_service"=>"manual"},
     {"name"=>"RatesDebug - Low / Medium / Extreme",
      "sku"=>"samesku",
      "quantity"=>3,
      "grams"=>0,
      "price"=>0,
      "vendor"=>"LastObelus",
      "requires_shipping"=>true,
      "taxable"=>true,
      "fulfillment_service"=>"manual"}],
   "currency"=>"USD"},
 "shop_url"=>"schumm-durgan-and-lang94.myshopify.com"}

=end