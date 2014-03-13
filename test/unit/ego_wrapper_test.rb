require_relative '../test_helper'

class EgoWrapperTest < ActiveSupport::TestCase
  include ActiveMerchant::Shipping
  
  def setup
    @origin = {country: "AU",
               postal_code: "2148",
               province: "ON",
               city: "Ottawa",
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
              {   country: "AU",
                  postal_code: "4000",
                  province: "ON",
                  city: "Ottawa",
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
  
  def test_ego_one_item
    booking_type = ""
    
    ego = EgoApiWrapper.new
    o = Location.new(@origin)
    d = Location.new(@destination)
    
    array = ego.get_rates(o, d, @item, booking_type)
    
    assert array.length == 1
    assert array[0]["service_name"] == "E-Go", "Service name should be E-go"
    assert !array[0]["total_price"].nil?, "price should not be nil"
    
  end
  
  
  def test_ego_multiple_items
     booking_type = ""

     ego = EgoApiWrapper.new
     o = Location.new(@origin)
     d = Location.new(@destination)
     array = ego.get_rates(o, d, @items, booking_type)
     assert array.length == 2
     assert array[0]["service_name"] == "E-Go", "Service name should be E-go"
     assert !array[0]["total_price"].nil?, "price should not be nil"
     
     assert array[1]["service_name"] == "E-Go", "Service name should be E-go"
     assert !array[1]["total_price"].nil?, "price should not be nil"     
   end
  
end
