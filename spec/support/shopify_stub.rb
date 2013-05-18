module ShopifyStub
  class << self
    def fixtures_dir
      File.join(File.dirname(__FILE__), '..', 'fixtures')
    end

    def rates_query
      @rates_query ||= Oj.load_file(File.join(fixtures_dir, 'rates_query.json'))
    end
  end
end