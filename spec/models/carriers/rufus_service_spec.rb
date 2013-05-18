require 'spec_helper'

describe Carriers::RufusService do
  let(:preference){ nil }
  let(:params){ {items: [name: "bob"]} }
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


  describe 
end
