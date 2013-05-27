module ShopifyStub
  class << self
    include ShippingHelpers
    def rates_query(fixture='')
      @rates_query ||= Oj.load_file(File.join(fixtures_dir, "#{fixture}rates_query.json"))
    end
  end
end