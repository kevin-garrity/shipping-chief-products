require 'spec_helper'
require 'oj'
require 'set'
describe ProductCache do
    let(:rates_query){ {
      origin: Destinations.US,
      destination:  Destinations.US,
      items: [
        {product_id: 111, variant_id: 41111},
        {product_id: 111, variant_id: 41112},
        {product_id: 112, variant_id: 41121},
        {product_id: 113, variant_id: 41131},        
        {product_id: 112, variant_id: 41122},
        {product_id: 111, variant_id: 41112}
      ]}
    }

  subject{ ProductCache.instance }
  
  describe '#resources_for_rates_query' do
    it "adds a product request for each product"    
    it "adds a product metafields request for each product"
    it "adds a metafields request for each variant"    
  end



  context "rates queries" do
    describe '#product_ids_in_order' do
      it 'returns the set of product ids' do
        # pp rates_query[:items]
        expect(subject.product_ids_in_order(rates_query[:items])).to eq(Set[111, 112, 113])
      end
    end

    describe '#variant_ids_in_order' do
      it 'returns the set of variant ids' do
        expect(subject.variant_ids_in_order(rates_query[:items])).to eq(Set[41111, 41112, 41121, 41131, 41122])
      end
    end
  end

end