require 'spec_helper'
require 'json'

describe RatesController do

  def json_shopify_params
    '{
         "rate": {
             "origin": {
                 "country": "CA",
                 "postal_code": "K1S4J3",
                 "province": "ON",
                 "city": "Ottawa",
                 "name": "",
                 "address1": "520 Cambridge Street South",
                 "address2": "",
                 "address3": "",
                 "phone": "",
                 "fax": "",
                 "address_type": "",
                 "company_name": ""
             },
             "destination": {
                 "country": "CA",
                 "postal_code": "K1S 3T7",
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
             },
             "items": [
                 {
                     "name": "My Product 3",
                     "sku": "",
                     "quantity": 1,
                     "grams": 1000,
                     "price": 2000,
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

  describe :shipping_rates do

    it "responds successfully with HTTP 200 OK!" do
      post :shipping_rates, valid_parameters_from_shopify
      expect(response).to be_success
      expect(response.code).to eq("200")
    end
  end
end

