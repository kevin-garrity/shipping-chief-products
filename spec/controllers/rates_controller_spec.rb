require 'spec_helper'
require 'json'

describe RatesController do

  def json_ca_dest 
    '{
    
         "country": "CA",
         "postal_code": "K1P 1J1",
         "province": "ON",
         "city": "Ottawa",
         "name": "Jason Normore",
         "address1": "520 Cambridge Street South Apt. 5",
         "address2": "",
         "address3": "",
         "phone": "7097433959",
         "fax": "",
         "address_type": "",
         "company_name": ""
    }'
  end
  
  def json_shopify_params
    '{
         "rate": {
             "origin": {
                 "country": "US",
                 "postal_code": "49686",
                 "province": "MI",
                 "city": "Traverse City",
                 "name": "",
                 "address1": "807 Airport Access Road",
                 "address2": "",
                 "address3": "",
                 "phone": "",
                 "fax": "",
                 "address_type": "",
                 "company_name": ""
             },
             "destination": {
                 "country": "US",
                 "postal_code": "06854",
                 "province": "CT",
                 "city": "Norwalk",
                 "name": "Jason Normore",
                 "address1": "999 Cambridge Street",
                 "address2": "",
                 "address3": "",
                 "phone": "7097433959",
                 "fax": "",
                 "address_type": "",
                 "company_name": ""
             },
             "items": [
                 {
                     "name": "My Product 3",
                     "sku": "x1",
                     "quantity": 1,
                     "grams": 1000,
                     "price": 2000,
                     "vendor": "TestVendor",
                     "requires_shipping": true,
                     "taxable": true,
                     "fulfillment_service": "manual"
                 },
                 {
                      "name": "My Product 4",
                      "sku": "x2",
                      "quantity": 1,
                      "grams": 2000,
                      "price": 3000,
                      "vendor": "TestVendor",
                      "requires_shipping": true,
                      "taxable": true,
                      "fulfillment_service": "manual"
                  }
             ],
             "currency": "CAD"
         }
      } '
  end

  def valid_parameters_from_shopify
    JSON.parse(json_shopify_params)
  end

  describe :fabusa_shop_rates do

    describe :shipping_rates do

      it "responds successfully with HTTP 200 OK!" do
        preference = FactoryGirl.create :preference_for_fabusa_shop 
        controller.stub!(:get_shop_prefence_from_request).and_return(preference) 
        post :shipping_rates, valid_parameters_from_shopify
        
        rates_json = JSON.parse(response.body)["rates"]
        puts("response is" + rates_json.to_s)
        expect(response).to be_success
        expect(response.code).to eq("200")
        expect(rates_json.length).to eq(6)        
      end

      context "when shipping cross countries" do
        it "should return rate" do
          preference = FactoryGirl.create :preference_for_fabusa_shop 
          controller.stub!(:get_shop_prefence_from_request).and_return(preference)      
          param = valid_parameters_from_shopify
          param["rate"]["destination"] = JSON.parse(json_ca_dest)
          post :shipping_rates, param
          expect(response).to be_success
          expect(response.code).to eq("200")
        end
      end
    
      context "when 'rates' is missing from request params" do
        it "should render NOTHING" do
        
          preference = FactoryGirl.create :preference_for_fabusa_shop 
          controller.stub!(:get_shop_prefence_from_request).and_return(preference)        
          post :shipping_rates

          response.body.strip.should be_empty
        end
      end

      context "when shopify passes us incomplete params" do

        it "should render NOTHING when origin is missing" do
          preference = FactoryGirl.create :preference_for_fabusa_shop 
          controller.stub!(:get_shop_prefence_from_request).and_return(preference)        
          invalid_params = valid_parameters_from_shopify
          invalid_params["rate"]["origin"] = {}

          expect { post :shipping_rates, invalid_params }.not_to raise_error(ActiveMerchant::Shipping::ResponseError)
          response.body.strip.should be_empty
        end

        it "should render NOTHING when destination is missing" do
          preference = FactoryGirl.create :preference_for_fabusa_shop 
          controller.stub!(:get_shop_prefence_from_request).and_return(preference)
                
          invalid_params = valid_parameters_from_shopify
          invalid_params["rate"]["destination"] = {}

          expect { post :shipping_rates, invalid_params }.not_to raise_error(ActiveMerchant::Shipping::ResponseError)
          response.body.strip.should be_empty
        end
      end
    end
  end
end

