require 'spec_helper'
require 'oj'

class Set
  def self.empty
    Set.new
  end
end

module ::Carriers::SpecService
  class Service < Carriers::RufusService
    include ShippingHelpers
    def decision_table_root
      Pathname.new(fixtures_dir).join('rufus')
    end

    def withShopify
      yield
    end
  end
end

describe Carriers::RufusService do
  before do
    ProductCache.instance.stub(:variants).and_return(ProductCacheStub.variants)
    @mock_shop = double('shop')
    @mock_shop.stub(:myshopify_domain).and_return('schumm-durgan-and-lang94.myshopify.com')
    ShopifyAPI::Shop.stub(:current).and_return(@mock_shop)
  end

  let(:preference){ nil }
  let(:params){ ShopifyStub.rates_query }
  let(:service){ }
  subject{ ::Carriers::SpecService::Service.new(preference, params) }
  describe '#decision_table_dir' do
    module ::Carriers::Bob
      class Service < ::Carriers::RufusService;end
    end
    subject{::Carriers::Bob::Service.new(nil,{})}
    it "should include the carrier" do
      expect(
        subject.decision_table_dir.to_s
        ).to match(%r{/rufus/carriers/bob$})
    end

    it "should respect the root" do
      subject.should_receive(:decision_table_root).at_least(:once).and_return(Pathname.new('/tmp/testroot/'))
      expect(
        subject.decision_table_dir.to_s
        ).to match(%r{^/tmp/testroot/carriers/bob$})
    end
  end

  describe '#decision_items' do
    it "stringifies keys of items" do
      subject.params = {items: [name: "bob"]}
      expect(subject.decision_items.first['name']).to eq("bob")
      expect(subject.decision_items.first[:name]).to be_nil
    end
  end

  describe '#decision_order' do
    it "stringifies keys of items" do
      subject.params = {items: [name: "bob"], destination: {province: 'BC', country_code: 'CA'}, currency: "CAD"}
      expect(subject.decision_order['province']).to eq("BC")
      expect(subject.decision_order['currency']).to eq("CAD")
      expect(subject.decision_order['country_code']).to eq("CA")
    end
  end


  describe '#construct_item_columns!' do
    before do
      subject.stub(:item_columns).and_return([
        'product.product_type',
        'variant.option1',
        'variant.option2',
        'variant.option3'
        ])
      @expected_columns = Set.new([
        'product_type',
        'option1',
        'option2',
        'option3'
      ])
    end
    it "adds the columns specified in item_columns" do
      subject.decision_items.each do |i| 
        expect( Set.new(i.keys).intersection(@expected_columns)
        ).to eq(Set.empty)
      end

      subject.construct_item_columns!

      subject.decision_items.each do |i| 
        expect( Set.new(i.keys).intersection(@expected_columns)
        ).to eq(@expected_columns)
      end
    end

    it "gets the values from the product cache" do
      # these are the values in the product cache, trust me
      subject.construct_item_columns!
      sample = subject.decision_items.detect{|i| i['name'] == "RatesDebug - Low / Medium / Extreme"}
      expect(sample['product_type']).to eq('Debug-1')
      expect(sample['option1']).to eq('Low')
      expect(sample['option2']).to eq('Medium')
      expect(sample['option3']).to eq('Extreme')
    end
  end

  describe '#construct_aggregate_columns!' do
    before do
      @expected_columns = Set.new([
        'total_item_quantity',
        'Debug-1 quantity',
        'Cube quantity',
        'product_types_set',
        'sku_set'
      ])
    end
    it "adds the columns specified in item_columns" do
      subject.decision_items.each do |i| 
        expect( Set.new(i.keys).intersection(@expected_columns)
        ).to eq(Set.empty)
      end

      subject.construct_item_columns!
      subject.construct_aggregate_columns!
      
      subject.decision_items.each do |i| 
        expect( Set.new(i.keys).intersection(@expected_columns)
        ).to eq(@expected_columns)
      end

      sample = subject.decision_items.detect{|i| i['name'] == "RatesDebug - Low / Medium / Extreme"}

      expect(sample['total_item_quantity']).to eq(7)
      expect(sample['Debug-1 quantity']).to eq(3)
      expect(sample['Cube quantity']).to eq(4)
      expect(sample['product_types_set']).to eq(Set['Cube', 'Debug-1'])
      expect(sample['sku_set']).to eq(Set["BOX/CUB/004WP", "BOX/CUB/001K", "samesku"])
    end
  end


  describe '#decisions' do
    let(:num_order_files){Dir[File.join(fixtures_dir,'rufus/carriers/spec_service/order/*.csv')].length}
    let(:num_item_files){Dir[File.join(fixtures_dir,'rufus/carriers/spec_service/item/*.csv')].length}
    specify{ 
      expect(subject.decisions).to be_a_kind_of(Hash) }

    specify{ 
      expect(subject.decisions['item'].length).to eq(num_item_files) }

    specify{
      expect(subject.decisions['order'].length).to eq(num_item_files) }

    specify{ 
      expect(subject.decisions['item'].first).
      to be_a_kind_of(Rufus::Decision::Table) }

    specify{ 
      expect(subject.decisions['order'].first).
      to be_a_kind_of(Rufus::Decision::Table) }

    specify{
      expect(subject.decisions['item'].first.matchers.map{|m| m.class}).
        to eq([Rudelo::Matchers::SetLogic, Rufus::Decision::Matchers::Numeric, Rufus::Decision::Matchers::Range, Rufus::Decision::Matchers::String])}
  end

  describe '#fetch_rates' do
    # these specs are more like acceptance tests than units
    it "uses a shopify session" do
      subject.stub(:withShopify).and_raise("ok")
      expect{subject.fetch_rates}.to raise_error("ok")
    end

  end
end

