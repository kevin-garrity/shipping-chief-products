class ProductCacheStub
  class << self
    include ShippingHelpers

    def variants
      @@variants ||= Oj.load_file(File.join(fixtures_dir, 'product_cache.json'), object: true, circular: true)
    end
  end
end
