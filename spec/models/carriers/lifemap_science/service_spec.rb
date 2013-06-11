# encoding: UTF-8
require 'spec_helper'

module Products
  class << self
    def cells
      "Human Embryonic Stem Cell Line ESI-017 - (46,XX) - Default Title"
    end

    def growth_media
      "Endothelial progenitor growth media ES-5007 - Default Title"
    end

    def differentiation_kit
      "PureStem Mural Differentiation Kit EM-2005 - Default Title"
    end

    def cheap_liquid_protein
      # freezedried
      "FAS Human Recombinant Protein - 5µg"
    end

    def expensive_liquid_protein
      # 
      "BMP2 Human Recombinant Protein - 1mg"
    end

    def freezedried_protein
      "Activin-A Human Recombinant Protein - 2µg"
    end

    def protein_needing_refrigeration
      "beta-NGF Human Recombinant Protein - 5µg"
    end

  end
end

RSpec.configure do |c|
  c.alias_it_should_behave_like_to :it_produces, 'produces'
end

shared_examples_for "correct rates" do |items, destination, expected_services|

  include_context "mock shopify"

  let(:params) {
    {
      origin: Destinations.US,
      destination: destination,
      items: items.map!{|item| ::Carriers::Debug::Service.sample_item(item) }
    }
  }
  let(:service){

   puts "@preference: #{@preference.inspect}"
   ::Carriers::LifemapScience::Service.new(@preference, params) }
  subject{ service.fetch_rates }

  it "returning the correct service names and rates" do
    puts "items: #{items.inspect}"
    puts "destination: #{destination.inspect}"
    puts "expected_services: #{expected_services.inspect}"

    result = subject
    puts "------------------------------------------------------------------"
    pp result
    puts "------------------------------------------------------------------"
    expect(result.length).to eq(expected_services.length)
    expected_services.each do |name, rate|
      returned_service = subject.detect{|s| s['service_name'] == name}
      expect(returned_service).to_not be_nil
      expect(returned_service['total_price']).to eq(rate)
    end
  end
end


describe Carriers::LifemapScience::Service do
  include_context "mock shopify"
  before(:each) do
    ProductCache.instance.stub(:variants).and_return(ProductCacheStub.new('lifemap').variants)
  end
  after(:each) do
    ProductCache.instance.unstub(:variants)
  end

  specify{expect(ProductCache.instance.variants.length).to eq(383)}

  context "BioTime products" do
    context "charges same rate for cells regardless of quantity"  do
      it_produces "correct rates",
      [
        Products.cells => 2
      ],
      Destinations.US.zone1, { "Overnight" => 3700 }

      # it_produces "correct rates",
      # [
      #   Products.cells => 20,
      # ],
      # Destinations.US.zone1, { "Overnight" => 3700 }

    end

    context "charges more for more than 4 media items" do
      it_produces "correct rates",
      [
        { Products.growth_media => 1 },
        { Products.differentiation_kit => 1 }
      ],
      Destinations.US.zone1, { "Overnight" => 3700 }

      it_produces "correct rates",
      [
        { Products.cells => 20 },
        { Products.growth_media => 2 },
        { Products.differentiation_kit => 2 }
      ],
      Destinations.US.zone1, { "Overnight" => 3700 }

      it_produces "correct rates",
      [
        { Products.growth_media => 2 },
        { Products.differentiation_kit => 3 }
      ],
      Destinations.US.zone1, { "Overnight" => 4044 }
    end

    it "charges dry ice fee if order contains growth media"
    it "does not charge dry ice fee if order only basal medium or glycosan kit"

    context "charges by zone" do
      let(:order){[
        Products.cells => 2
      ]}

      it_produces "correct rates",
      new.order,
      Destinations.US.zone2, { "Overnight" => 6400 }

      it_produces "correct rates",
      new.order,
      Destinations.US.zone3, { "Overnight" => 7178 }

      it_produces "correct rates",
      new.order,
      Destinations.US.zone4, { "Overnight" => 7400 }

      it_produces "correct rates",
      new.order,
      Destinations.US.zone5, { "Overnight" =>7400 }
    end

  end

  context "ProSpec products" do
    context "requires refrigeration" do
      context "less than 7 and less than 2500.00" do
        it_produces "correct rates",
        [Products.cheap_liquid_protein => 6],
        Destinations.US, { 
          "FedEx International Express Styrofoam Box" => 9000,
          "FedEx NextDay Styrofoam Box" => 10500 }
      end

      context "more than 6" do
        it_produces "correct rates",
        [Products.cheap_liquid_protein => 7],
        Destinations.US, { "FedEx International Express Styrofoam Box" => 14000 }
      end

      context "order more than 2500" do
        it_produces "correct rates",
        [Products.expensive_liquid_protein => 1],
        Destinations.US, { "FedEx International Express Styrofoam Box" => 14000 }
      end

      context "zone 2" do
        it_produces "correct rates",
        [Products.cheap_liquid_protein => 6],
        Destinations.CA, { "FedEx International Express Styrofoam Box" => 10000 }
      end

      context "zone 3" do
        it_produces "correct rates",
        [Products.cheap_liquid_protein => 6],
        Destinations.AU, { "FedEx International Express Styrofoam Box" => 19500 }
      end

      context "zone 4" do
        it_produces "correct rates",
        [Products.cheap_liquid_protein => 6],
        Destinations.PL, { "FedEx International Express Styrofoam Box" => 19500 }
      end

      context "zone 5" do
        it_produces "correct rates",
        [Products.cheap_liquid_protein => 6],
        Destinations.ZA, { "FedEx International Express Styrofoam Box" => 27000 }
      end

    end

    context "doesn't require refrigeration" do
    end
  end
end



# shared example
# pass item hash
# pass destination hash
# pass expected services => rates

