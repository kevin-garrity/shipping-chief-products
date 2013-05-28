module Carriers
  module Debug
    class Service < ::Carriers::Service
      def fetch_rates
        ppl params
        # Rails.logger.info("returning #{sample_response.inspect}")
        return sample_response_1
      end

      def sample_response_2
        [
        {
          "service_name"=>"FedEx Ground",
          "service_code"=>"FedEx Ground",
          "total_price"=>6724,
          "currency"=>"USD"
        },
        {
          "service_name"=>"FedEx Express Saver",
          "service_code"=>"FedEx Express Saver",
          "total_price"=>14640,
          "currency"=>"USD"
        },
        {
          "service_name"=>"FedEx 2 Day",
          "service_code"=>"FedEx 2 Day",
          "total_price"=>18520,
          "currency"=>"USD"
        },
        {
          "service_name"=>"FedEx Standard Overnight",
          "service_code"=>"FedEx Standard Overnight",
          "total_price"=>36971,
          "currency"=>"USD"
        },
        {
          "service_name"=>"FedEx Priority Overnight",
          "service_code"=>"FedEx Priority Overnight",
          "total_price"=>37776,
          "currency"=>"USD"
        },
        {
          "service_name"=>"FedEx First Overnight",
          "service_code"=>"FedEx First Overnight",
          "total_price"=>60510,
          "currency"=>"USD"}
        ]
      end
      def sample_response_1
        [
          {
            "service_name"=>"canadapost-overnight",
            "service_code"=>"ON",
            "total_price"=>"1295",
            "currency"=>"CAD",
            "custom_field" => "yo, shipping. duh",
            "min_delivery_date"=>"2013-04-12 14:48:45 -0400",
            "max_delivery_date"=>"2013-04-12 14:48:45 -0400",
          },
          {
            "service_name"=>"fedex-2dayground",
            "service_code"=>"1D",
            "total_price"=>"2934",
            "currency"=>"USD",
            "min_delivery_date"=>"2013-04-12 14:48:45 -0400",
            "max_delivery_date"=>"2013-04-12 14:48:45 -0400"
          },
          {
            "service_name"=>"fedex-2dayground",
            "service_code"=>"1D",
            "total_price"=>"2934",
            "currency"=>"USD",
            "min_delivery_date"=>"2013-04-12 14:48:45 -0400",
            "max_delivery_date"=>"2013-04-12 14:48:45 -0400"
          }
        ]
      end

      SAMPLE_SERVICE_QUERY = {
        :origin=> {
          "country"=>"CA",
          "postal_code"=>"V7V 7V7",
          "province"=>"BC",
          "city"=>"Somecity",
          "name"=>nil,
          "address1"=>"123 Some Street",
          "address2"=>"",
          "address3"=>nil,
          "phone"=>nil,
          "fax"=>nil,
          "address_type"=>nil,
          "company_name"=>nil
        },
        :destination=> {
          "country"=>"US",
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
          "company_name"=>nil
        },
        :items=> []
      }

      SAMPLE_ITEM = {
        "name"=>"RatesDebug - Low / Medium / Extreme",
        "sku"=>"samesku",
        "quantity"=>2,
        "grams"=>0,
        "price"=>0,
        "vendor"=>"LastObelus",
        "requires_shipping"=>true,
        "taxable"=>true,
        "fulfillment_service"=>"manual",
        "product_id"=>135576025,
        "variant_id"=>309727645
      }

      def self.sample_item(item=nil)
        out = SAMPLE_ITEM.dup
        return out unless item
        name = nil
        case item
        when String
          name = item
          item = {}
        when Hash
          item = item.stringify_keys
          name = item.delete('name')
          if name.nil?
            raise "don't know what to do with #{item.inspect}" unless item.keys.length == 1
            name, item = item.first
            item = item.is_a?(Hash) ? item.stringify_keys : {'quantity' => item}
          end
        end
        variant = ProductCache.instance.variants[name]
        raise "couldn't find item matching #{item.inspect}" if variant.nil?

        out.merge!(
          "name"=> name,
          "sku"=>variant.sku,
          "quantity"=>1,
          "grams"=>variant.grams,
          "price"=>variant.price,
          "vendor"=>"FAB",
          "requires_shipping"=>variant.requires_shipping,
          "taxable"=>variant.taxable,
          "fulfillment_service"=>variant.fulfillment_service,
          "product_id"=>variant.product.id,
          "variant_id"=>variant.id
        )
        out.merge!(item)
        out
      end

      def self.sample_query(opts={})
        opts = {items: opts} unless opts.is_a?(Hash)
        opts = opts.stringify_keys
        out = SAMPLE_SERVICE_QUERY.dup.stringify_keys
        dest = opts.delete('destination')
        if dest
          out['destination'].merge!(dest)
        end
        items = opts.delete('items')
        items = [items].flatten
        items.each do |item|      
          out['items'] << sample_item(item)
        end
        out
      end
    end
  end
end

=begin
sample params sent by shopify:

{:origin=>
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
 :destination=>
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
 :items=>
  [{"name"=>"Cube Gift Box - 20 Pearl White Gift Boxes",
    "sku"=>"BOX/CUB/004WP",
    "quantity"=>3,
    "grams"=>4990,
    "price"=>5920,
    "vendor"=>"FAB",
    "requires_shipping"=>true,
    "taxable"=>false,
    "fulfillment_service"=>"manual",
    "product_id"=>126245474,
    "variant_id"=>286982472},
   {"name"=>"Cube Gift Box - 20 Natural Brown Kraft Gift Boxes",
    "sku"=>"BOX/CUB/001K",
    "quantity"=>1,
    "grams"=>4990,
    "price"=>5920,
    "vendor"=>"FAB",
    "requires_shipping"=>true,
    "taxable"=>false,
    "fulfillment_service"=>"manual",
    "product_id"=>126245474,
    "variant_id"=>286982482},
   {"name"=>"RatesDebug - High / High / High",
    "sku"=>"samesku",
    "quantity"=>1,
    "grams"=>1000,
    "price"=>100000,
    "vendor"=>"LastObelus",
    "requires_shipping"=>true,
    "taxable"=>true,
    "fulfillment_service"=>"manual",
    "product_id"=>135576025,
    "variant_id"=>309737933},
   {"name"=>"RatesDebug - Low / Medium / Extreme",
    "sku"=>"samesku",
    "quantity"=>2,
    "grams"=>0,
    "price"=>0,
    "vendor"=>"LastObelus",
    "requires_shipping"=>true,
    "taxable"=>true,
    "fulfillment_service"=>"manual",
    "product_id"=>135576025,
    "variant_id"=>309727645}],
 :currency=>"USD"}
=end
