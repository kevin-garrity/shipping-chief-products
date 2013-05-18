module ShopifyStub
  class << self
    include ShippingHelpers
    def rates_query
      @rates_query ||= Oj.load_file(File.join(fixtures_dir, 'rates_query.json'))
    end
  end
end