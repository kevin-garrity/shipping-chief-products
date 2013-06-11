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
  include_context "mock shopify"

  before(:each) do
    ProductCache.instance.stub(:variants).and_return(ProductCacheStub.new('').variants)
  end
  after(:each) do
    ProductCache.instance.unstub(:variants)
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
      subject.params = {items: [variant_id: 286982344], destination: {province: 'BC', country_code: 'CA'}, currency: "CAD"}
      expect(subject.decision_order['province']).to eq("BC")
      expect(subject.decision_order['currency']).to eq("CAD")
      expect(subject.decision_order['country_code']).to eq("CA")
    end
  end


  describe '#construct_item_columns!' do
    before do
      subject.stub(:item_columns).and_return([
        'product.product_type',
        'product.option1_name',
        'product.option2_name',
        'product.option3_name',
        'variant.option1',
        'variant.option2',
        'variant.option3',
        'metafields'
        ])
      @expected_columns = Set.new([
        'product_type',
        'option1_name',
        'option2_name',
        'option3_name',
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
        expect( i.keys ).to include("vendor")
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

    it "adds metafield columns" do
      subject.construct_item_columns!
      sample = subject.decision_items.detect{|i| i['name'] == "RatesDebug - Low / Medium / Extreme"}
      expect(sample['wby.ship:test_variant']).to eq('Low / Medium / Extreme metafield on variant')
      expect(sample['wby.ship:test_product']).to eq('RatesDebug metafield on product')
    end

  end

  describe '#construct_aggregate_columns!' do
    before do
      @expected_columns = Set.new([
        'total_quantity',
        'Debug-1 quantity',
        'Cube quantity',
        'product_types_set',
        'sku_set',
        'vendor_set',
        'total_order_price'
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

      expect(sample['total_quantity']).to eq(7)
      expect(sample['Debug-1 quantity']).to eq(3)
      expect(sample['Cube quantity']).to eq(4)
      expect(sample['product_types_set']).to eq(Set['Cube', 'Debug-1'])
      expect(sample['sku_set']).to eq(Set["BOX/CUB/004WP", "BOX/CUB/001K", "samesku"])
      expect(sample['option1_name']).to eq("Kraftiness")
      expect(sample['option2_name']).to eq("Zaniness")
      expect(sample['option3_name']).to eq(nil)
      expect(sample['vendor_set']).to eq(Set["FAB", "LastObelus"])

      expect(sample['wby.ship:test_product:set']).to eq(Set["Cube Gift Box metafield on product","RatesDebug metafield on product"])
      expect(sample['wby.ship:test_variant:set']).to eq(Set[
        "20 Pearl White Gift Boxes metafield on variant",
        "20 Natural Brown Kraft Gift Boxes metafield on variant",
        "High / High / High metafield on variant",
        "Low / Medium / Extreme metafield on variant"])

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

  describe '#transform_item_decisions' do
    before do
      @item1 = {"in-1" => "old-1-1", 'in-2' =>'old-1-2'}
      @item2 = {"in-1" => "old-2", 'in-2' =>'old-2-2'}
      subject.stub(:decision_items).and_return([@item1, @item2])
      @dec_1 = mock('first decision')
      @dec_2 = mock('second decision')
      @dec_1.stub(:transform).with(@item1).and_return(@item1)
      @dec_1.stub(:transform).with(@item2).and_return(@item2)
      @dec_2.stub(:transform).with(@item1).and_return(@item1)
      @dec_2.stub(:transform).with(@item2).and_return(@item2)
      subject.stub(:decisions).and_return({'item' => [@dec_1, @dec_2]})
    end
    it "transforms each item with each item decision" do
      @dec_1.should_receive(:transform).with(@item1).once.and_return(@item1)
      @dec_1.should_receive(:transform).with(@item2).once.and_return(@item2)
      @dec_2.should_receive(:transform).with(@item1).once.and_return(@item1)
      @dec_2.should_receive(:transform).with(@item2).once.and_return(@item2)
      subject.transform_item_decisions
    end
    it "expands each item result" do
      @item1.should_receive(:expand).at_least(:once).and_return([@item1])
      @item2.should_receive(:expand).at_least(:once).and_return([@item2])
      subject.transform_item_decisions
    end

    it "only includes new or modified columns in the result" do
      intermediate = {
        'in-1' => 'old-1-1', 'in-2' => 'old-1-2', 'new-1' => 'blah'
        }
      @dec_1.should_receive(:transform).with(@item1).once.and_return(intermediate)
      @dec_2.should_receive(:transform).with(intermediate).once.and_return(intermediate)

      result = subject.transform_item_decisions
      expect(result.first).to have_key('new-1')
      expect(result.first).to_not have_key('in-1')
      expect(result.first).to_not have_key('in-2')
    end
  end

  describe  "item decisions" do
    context "fixture with item fees & pkg choices" do
      before do
        subject.stub(:decision_table_dir).and_return(
          Pathname.new(fixtures_dir).join('rufus','carriers','transform_item_sums_spec'))
      end

      it "sums fees and chooses max of pkg" do
        subject.stub(:decision_items).and_return([
          {name: 'one', sku: 'YY-1', product_type: 'WIDGET'}.stringify_keys,
          {name: 'one', sku: 'XX-1', product_type: 'VASE'}.stringify_keys
        ])
        transformed = subject.transform_item_decisions
        expect(transformed).to eq([
          {'sum:big item fee' => '2.00', 'max:pkg' => '15_box'},
          {'sum:big item fee' => '4.33', 'max:pkg' => '20_crate'}
        ]
        )

        services = subject.extract_services_from_item_decision_results(transformed)
        expect(services).to eq(
            :all=>{"big item fee"=>6.33, "pkg"=>"20_crate"}
        )
      end

      it "handles no matches" do
        subject.stub(:decision_items).and_return([
          {name: 'one', sku: 'AA-1', product_type: 'GOOBER'}.stringify_keys,
          {name: 'one', sku: 'BB-1', product_type: 'SPLING'}.stringify_keys
        ])
        transformed = subject.transform_item_decisions
        expect(transformed).to eq([
          {"max:pkg"=>"10_box"}, {"max:pkg"=>"10_box"}
        ])

        services = subject.extract_services_from_item_decision_results(transformed)
        expect(services).to eq(
            :all => {"pkg"=>"10_box"}
        )
      end
    end
  end

  describe '#extract_services_from_item_decision_results' do
    it "collapses set of all item results by  service_name_column"
    it "converts columns with multiple results to sets"
    it "sums sum: columns"
  end

  describe '#transform_order_decisions' do
    let(:transformed){subject.transform_order_decisions}
    context "a single decision table" do
      before do
        subject.stub(:decision_table_dir).and_return(
          Pathname.new(fixtures_dir).join('rufus','carriers','transform_order_single_spec'))
      end
      it "returns a single result" do
        subject.stub(:decision_order).and_return({total_quantity: '5'}.stringify_keys)
        expect(transformed).to be_a_kind_of(Array)
        expect(transformed.length).to eq(1)
        expect(transformed.first["Service Name"]).to eq("should get first row only")
      end
    end
    context "a single decision table with accumulate and multiple matches" do
      before do
        subject.stub(:decision_table_dir).and_return(
          Pathname.new(fixtures_dir).join('rufus','carriers','transform_order_accumulate_spec'))
      end
      it "returns an array of results" do
        $logon = true
        subject.stub(:decision_order).and_return({total_quantity: '5'}.stringify_keys)
        expect(transformed).to be_a_kind_of(Array)
        expect(transformed.length).to eq(2)
        expect(transformed.first["Service Name"]).to eq("should get first row")
        expect(transformed.last["Service Name"]).to eq("should also get second")
      end
    end
    context "multiple decision tables" do
      before do
        subject.stub(:decision_table_dir).and_return(
          Pathname.new(fixtures_dir).join('rufus','carriers','transform_order_multi_spec'))
      end
      it "runs all decision tables and returns an array of results" do
        $logon = true
        subject.stub(:decision_order).and_return({total_quantity: '5', province: 'ON', num_items: 4}.stringify_keys)
        expect(transformed).to be_a_kind_of(Array)
        expect(transformed.length).to eq(3)

        # service-1, price from zone-2, handling fee 5
        expect(transformed[0]["Service Name"]).to eq("service-1")
        expect(transformed[0]["price"]).to eq("112")
        expect(transformed[0]["handling fee"]).to eq("5")
        # service-2, price from zone-2, handling fee 5
        expect(transformed[1]["Service Name"]).to eq("service-2")
        expect(transformed[1]["price"]).to eq("122")
        expect(transformed[1]["handling fee"]).to eq("5")
        # service-3, price from zone-2, handling fee 5
        expect(transformed[2]["Service Name"]).to eq("service-3")
        expect(transformed[2]["price"]).to eq("132")
        expect(transformed[2]["handling fee"]).to eq("5")
      end
    end
  end


  describe '#calculate_price' do
    it "recognizes the base price" do
      expect(subject.calculate_price({'price' => '25.4'})).to eq(25.4)
    end
    it "adds fees" do
      expect(subject.calculate_price({'price' => '25.4', 'first fee' => '1.0', 'other Fee' => '0.3'})).to eq(26.7)
    end

    it "recognizes total_price" do
      expect(subject.calculate_price({'price' => '8000', 'total_price' => '25.4', 'first fee' => '1.0', 'other Fee' => '0.3'})).to eq(26.7)
    end

    it "recognizes xxx price" do
      expect(subject.calculate_price({'xxx price' => '25.4', 'first fee' => '1.0', 'other Fee' => '0.3'})).to eq(26.7)
    end
  end

  describe '#service_name' do
    it "returns value of column spec'd in service_name_column" do
      subject.should_receive(:service_name_column).and_return('whatever')
      expect(subject.service_name({'whatever' => 'the name'})).to eq('the name')
    end
  end

  describe '#service_code' do
    it "returns value of column spec'd in service_name_column" do
      subject.should_receive(:service_name_column).and_return('whatever')
      expect(subject.service_code({'whatever' => 'the name'})).to eq('the name')
    end
  end

  describe '#construct_rates' do
    before do
      @serv1 =  {id: 'serv-1', currency: 'CAD'}.stringify_keys
      @serv2 = {id: 'serv-2', currency: 'CAD'}.stringify_keys
      subject.should_receive(:service_name).with(@serv1).and_return('service_name1')
      subject.should_receive(:service_name).with(@serv2).and_return('service_name2')

      subject.should_receive(:service_code).with(@serv1).and_return('service_code1')
      subject.should_receive(:service_code).with(@serv2).and_return('service_code2')

      subject.should_receive(:calculate_price).with(@serv1).at_least(:once).and_return('price1')
      subject.should_receive(:calculate_price).with(@serv2).at_least(:once).and_return('price2')
    end
    let(:selected_services){ [ @serv1, @serv2 ] }
    let(:construct_rates){ subject.construct_rates(selected_services)}
    it "returns an array of rates" do
      expect(construct_rates).to be_a_kind_of(Array)
    end
    it "returns a rate for each selected service" do
      expect(construct_rates.length).to eq(selected_services.length)
    end
    it "sets total_price using calculate_price" do
      expect(construct_rates[0]['total_price']).to eq('price1')
      expect(construct_rates[1]['total_price']).to eq('price2')
    end
    it "sets service_name using service_name" do
      expect(construct_rates[0]['service_name']).to eq('service_name1')
      expect(construct_rates[1]['service_name']).to eq('service_name2')
    end
    it "sets service_code using service_code" do
      expect(construct_rates[0]['service_code']).to eq('service_code1')
      expect(construct_rates[1]['service_code']).to eq('service_code2')
    end
    it "sets currency" do
      expect(construct_rates[0]['currency']).to eq('CAD')
      expect(construct_rates[1]['currency']).to eq('CAD')
    end
  end

  describe '#fetch_rates' do
    before(:each) do
      ProductCache.instance.stub(:variants).and_return(ProductCacheStub.new('cells').variants)
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

