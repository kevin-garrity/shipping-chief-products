require 'spec_helper'

RSpec.configure do |c|
  c.alias_it_should_behave_like_to :it_produces, 'produces'
end    
shared_examples_for "correct rates for" do |items, destination, expected_services|
  let(:preference){ nil }
  let(:params) {
    {
      'origin' => destination,
      'items' => items
    }
  }
  let(:service){ ::Carriers::LifemapScience::Service.new(preference, params) }
  subject{ service.fetch_rates }

  it "returns the correct service names and rates" do
    expected_services.each do |name, rate|
      returned_service = subject.detect{|s| s['service_name'] == name}
      expect(returned_service).to_not be_nil
      expect(returned_service['total_price']).to eq(rate)
    end
  end


end


describe Carriers::LifemapScience::Service do
  before do
    ProductCache.instance.stub(:variants).and_return(ProductCacheStub.new('lifemap').variants)
    @mock_shop = double('shop')
    @mock_shop.stub(:myshopify_domain).and_return('lifemap_science.myshopify.com')
    ShopifyAPI::Shop.stub(:current).and_return(@mock_shop)
  end


  context "BioTime products"
    let(:us){ {country: 'US'} }
    let(:zone1){ us.merge(province: 'CA') }
    let(:zone2){ us.merge(province: 'UT') }
    let(:zone3){ us.merge(province: 'CO') }
    let(:zone4){ us.merge(province: 'MO') }
    let(:zone5){ us.merge(province: 'OH') }
    context "charges same rate for cells regardless of quantity"  do
      it_produces "correct rates for"
    end
    it "charges more for more than 4 media items"
    it "charges dry ice fee if order contains media item"
    it "does not charge dry ice fee if order only contains cells"
    it "charges by zone"
end


# shared example
# pass item hash
# pass destination hash
# pass expected services => rates

