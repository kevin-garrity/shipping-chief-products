require_relative '../test_helper'

class PurolatorWrapperTest < ActiveSupport::TestCase
  include ActiveMerchant::Shipping
  
  def setup
     @origin = {country: "CA",
                postal_code: "L4W5M8",
                province: "ON",
                city: "Mississauga",
                name: "",
                address1: "520 Cambridge Street South",
                address2: "",
                address3: "",
                phone: "",
                fax: "",
                address_type: "",
                company_name: ""
            }
     @destination =
               {   country: "CA",
                   postal_code: "V3N2G9",
                   province: "BC",
                   city: "Burnaby",
                   name: "Jason Normore",
                   address1: "520 Cambridge Street South Apt. 5",
                   address2: "",
                   address3: "",
                   phone: "7097433959",
                   fax: "",
                   address_type: "",
                   company_name: ""
               }
     @item = [
               { name: "My Product 3",
                   sku: "",
                   quantity: 1,
                   grams:  1000,
                   price: 2000,
                   vendor: "TestVendor",
                   requires_shipping: true,
                   taxable: true,
                   fulfillment_service: "manual",
                   height: 10,
                   width: 10,
                   length: 10
               }
             ]

     @items = [
               { name: "My Product 3",
                   sku: "",
                   quantity: 1,
                   grams:  1000,
                   price: 2000,
                   vendor: "TestVendor",
                   requires_shipping: true,
                   taxable: true,
                   fulfillment_service: "manual",
                   height: 10,
                   width: 10,
                   length: 10
               },
               { name: "My Product 4",
                   sku: "",
                   quantity: 1,
                   grams:  2000,
                   price: 2000,
                   vendor: "TestVendor",
                   requires_shipping: true,
                   taxable: true,
                   fulfillment_service: "manual",
                   height: 10,
                   width: 20,
                   length: 30
               }
             ]            
   end
  
  def test_get_rates
    p = PurolatorWrapper.new
    o = Location.new(@origin)
    d = Location.new(@destination)

    p.get_rates(o,d, @item)
  end
  
end