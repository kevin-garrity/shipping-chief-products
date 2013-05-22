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
    ProductCache.instance.stub(:variants).and_return(ProductCacheStub.new('product_cache').variants)
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
      
      # pp subject.decision_items
      # puts "--------------"
      # pp subject.decision_order

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
      expect(sample['option1_name']).to eq("Kraftiness")
      expect(sample['option2_name']).to eq("Zaniness")
      expect(sample['option3_name']).to eq(nil)
    end
  end




  describe '#decisions' do
    let(:num_order_files){Dir[File.join(fixtures_dir,'rufus/carriers/spec_service/order/*.csv')].length}
    let(:num_item_files){Dir[File.join(fixtures_dir,'rufus/carriers/spec_service/item/*.csv')].length}
    specify{ 
      expect(subject.decisions).to be_a_kind_of(Hash) }

    it "has an item decision for each file in service/item/" do
      expect(subject.decisions['item'].length).to eq(num_item_files) 
    end

    it "has an order decision for each file in service/order/" do
      expect(subject.decisions['order'].length).to eq(num_item_files) 
    end

    it "returns instances of Rufus::Decision::Table" do
      expect(
        (subject.decisions['order'] + subject.decisions['item']).all? {|entry|
          entry.is_a?(Rufus::Decision::Table)
        }).to be_true
    end

    it "adds Rudelo SetLogic matcher to each table" do
      expect(subject.decisions['item'].first.matchers.map{|m| m.class}).
        to eq([Rudelo::Matchers::SetLogic, Rufus::Decision::Matchers::Numeric, Rufus::Decision::Matchers::Range, Rufus::Decision::Matchers::String])
    end
  end

  describe 'transform_order_decisions' do
    context "a single decision table" do
      before do
        subject.stub(:decision_table_dir).and_return(
          Pathname.new(fixtures_dir).join('rufus','carriers','transform_order_single_spec'))
      end
      # let(:subject) {   ::Carriers::SpecService::Service.new(preference, params) }
      let(:transformed){subject.transform_order_decisions}
      it "returns a single result" do
        subject.stub(:decision_order).and_return({total_quantity: '5'}.stringify_keys)
        expect(transformed).to be_a_kind_of(Array)
        expect(transformed.length).to eq(1)
        expect(transformed.first["Service Name"]).to eq("should get first row only")
      end
    end
    context "a single decision table with accumulate and multiple matches" do
    end
    context "multiple decision tables" do
    end
  end


  describe '#fetch_rates' do
    before do
      ProductCache.instance.stub(:variants).and_return(ProductCacheStub.new('cells_product_cache').variants)
    end
    # these specs are more like acceptance tests than units
    it "uses a shopify session" do
      subject.stub(:withShopify).and_raise("ok")
      expect{subject.fetch_rates}.to raise_error("ok")
    end

    context "an order decision table and an item decision table" do

    end

    
  end
end

