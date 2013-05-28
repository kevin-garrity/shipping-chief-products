require 'spec_helper'

RSpec.configure do |c|
  c.alias_it_should_behave_like_to :it_produces, 'produces'
end

shared_examples_for "correct rates for" do |items, destination, expected_services|

  include_context "mock shopify"

  let(:params) {
    {
      'origin' => destination,
      'items' => items.map!{|item| ::Carriers::Debug::Service.sample_item(item) }
    }
  }
  let(:service){

   puts "@preference: #{@preference.inspect}"
   ::Carriers::LifemapScience::Service.new(@preference, params) }
  subject{ service.fetch_rates }

  it "returns the correct service names and rates" do
    puts "items: #{items.inspect}"
    puts "destination: #{destination.inspect}"
    puts "expected_services: #{expected_services.inspect}"
    pp subject
    expected_services.each do |name, rate|
      returned_service = subject.detect{|s| s['service_name'] == name}
      expect(returned_service).to_not be_nil
      expect(returned_service['total_price']).to eq(rate)
    end
  end


end


describe Carriers::LifemapScience::Service do
  include_context "mock shopify"
  before do
    ProductCache.instance.stub(:variants).and_return(ProductCacheStub.new('lifemap').variants)
  end

  specify{expect(ProductCache.instance.variants.length).to eq(383)}

  context "BioTime products" do
    context "charges same rate for cells regardless of quantity"  do
      it_produces "correct rates for",
      [
        "Human Embryonic Stem Cell Line ESI-017 - (46,XX) - Default Title" => 2
      ],
      Destinations.zone1, {}

    end
    it "charges more for more than 4 media items"
    it "charges dry ice fee if order contains media item"
    it "does not charge dry ice fee if order only contains cells"
    it "charges by zone"
  end
end



# shared example
# pass item hash
# pass destination hash
# pass expected services => rates

