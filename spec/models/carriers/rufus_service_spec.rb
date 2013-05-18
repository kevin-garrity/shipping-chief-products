require 'spec_helper'

describe Carriers::RufusService do
 describe '#decision_table_dir' do
  it "should include the carrier" do
    module ::Carriers::Bob
      class Service < ::Carriers::RufusService;end
    end
    expect(
    ::Carriers::Bob::Service.new(nil,{}).decision_table_dir.to_s
    ).to match(%r{/rufus/carriers/bob$})
  end

 end

end
