require 'spec_helper'
require 'oj'

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
  subject{ Carriers::RufusService.new(preference, params) }
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


  describe '#construct_item_columns!' do
    before do
      subject.stub(:item_columns).and_return([
        'product.product_type',
        'variant.option1',
        'variant.option2',
        'variant.option3'
        ])
      @expected_columns = [
        'product_type',
        'option1',
        'option2',
        'option3'
      ]
    end
    it "adds the columns specified in item_columns" do
      expect(subject.decision_items.all?{ |i|
        @expected_columns.all?{|c| ! i.keys.include?(c) }
      }).to be_true
      subject.construct_item_columns!
      expect(subject.decision_items.any?{ |i|
        @expected_columns.any?{|c| ! i.keys.include?(c) }
      }).to be_false
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
end

