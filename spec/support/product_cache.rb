class ProductCacheStub
  class << self
    include ShippingHelpers

    def variants
      @@variants ||= Oj.load_file(File.join(fixtures_dir, 'product_cache.json'), object: true, circular: true)
    end

    def product_types
      @@product_types ||= variants.values.map{|v| v.product.product_type}.uniq.sort
    end

  end
end
