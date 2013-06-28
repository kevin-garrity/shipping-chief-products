# encoding: UTF-8
require 'spec_helper'

describe "#sample_item" do
  before(:each) do
    ProductCache.instance.stub(:variants).and_return(ProductCacheStub.new('lifemap').variants)
  end
  after(:each) do
    ProductCache.instance.unstub(:variants)
  end
  let(:subject){ ::Carriers::Debug::Service }


  it "retrieves item from cache" do
    expect(subject.sample_item("Activin-A Human Recombinant Protein - 2µg")).to eq({
      "name"=>"Activin-A Human Recombinant Protein - 2µg",
      "sku"=>"LM-CYT-569",
      "quantity"=>1,
      "grams"=>0,
      "price"=>"4750",
      "vendor"=>"ProSpec",
      "requires_shipping"=>true,
      "taxable"=>true,
      "fulfillment_service"=>"manual",
      "product_id"=>128215174,
      "variant_id"=>290000178
    })
  end

  it "overrides values" do
    expect(subject.sample_item(
      name: "Activin-A Human Recombinant Protein - 2µg", quantity: 4, price: '124')).to eq({
      "name"=>"Activin-A Human Recombinant Protein - 2µg",
      "sku"=>"LM-CYT-569",
      "quantity"=>4,
      "grams"=>0,
      "price"=>"124",
      "vendor"=>"ProSpec",
      "requires_shipping"=>true,
      "taxable"=>true,
      "fulfillment_service"=>"manual",
      "product_id"=>128215174,
      "variant_id"=>290000178
    })
  end

  it "understands alternative syntax" do
    expect(subject.sample_item( "Activin-A Human Recombinant Protein - 2µg" => {quantity: 4, price: '124'})).to eq({
      "name"=>"Activin-A Human Recombinant Protein - 2µg",
      "sku"=>"LM-CYT-569",
      "quantity"=>4,
      "grams"=>0,
      "price"=>"124",
      "vendor"=>"ProSpec",
      "requires_shipping"=>true,
      "taxable"=>true,
      "fulfillment_service"=>"manual",
      "product_id"=>128215174,
      "variant_id"=>290000178
    })
  end


end