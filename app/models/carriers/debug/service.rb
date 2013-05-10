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
  [{"name"=>"Cube Gift Box - 20 Pearl White Gift Boxes",
    "sku"=>"BOX/CUB/004WP",
    "quantity"=>2,
    "grams"=>4990,
    "price"=>5920,
    "vendor"=>"FAB",
    "requires_shipping"=>true,
    "taxable"=>false,
    "fulfillment_service"=>"manual"}],
 "currency"=>"USD"}

 =end