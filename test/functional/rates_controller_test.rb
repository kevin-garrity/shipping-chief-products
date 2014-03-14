require_relative '../test_helper.rb'


class RatesControllerTest < ActionController::TestCase
  fixtures :shops, :preference, :chief_products_preference, :cached_products

  def setup
    
    @rates_hash =  {
           origin: {
               country: "AUS",
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
           },
           destination: {
               country: "AUS",
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
           },
           items: [
               {
                   name: "My Product 1",
                   product_id: 1,
                   sku: "",
                   quantity: 1,
                   grams: 1000,
                   price: 2000,
                   vendor: "TestVendor",
                   requires_shipping: true,
                   taxable: true,
                   fulfillment_service: "manual"
               },
               {
                    name: "My Product 2",
                    product_id: 2,
                    sku: "",
                    quantity: 1,
                    grams: 1000,
                    price: 2000,
                    vendor: "TestVendor",
                    requires_shipping: true,
                    taxable: true,
                    fulfillment_service: "manual"
                }
           ],
           currency: "AUD"
       }
  end
  
  def test_chief_products_rates
    @request.env["HTTP_X_SHOPIFY_SHOP_DOMAIN"] = shops(:chief_products_test_shop).domain
    
    post :shipping_rates, {:rate=>@rates_hash}
    puts("response is #{@response.body.inspect}")
    json = ActiveSupport::JSON.decode @response.body
    puts("response json #{json}")
    
    assert_response :success

  end
  
  
  def test_purolator_rates
     @request.env["HTTP_X_SHOPIFY_SHOP_DOMAIN"] = shops(:chief_products_test_shop).domain

     post :shipping_rates, {:rate=>@rates_hash}
     puts("response is #{@response.body.inspect}")
     json = ActiveSupport::JSON.decode @response.body
     puts("response json #{json}")

     assert_response :success

   end
  
end
