class ProductCacheStub
  class << self
    def fixtures_dir
      File.join(File.dirname(__FILE__), '..', 'fixtures')
    end

    def variants
      @@variants ||= Oj.load_file(File.join(fixtures_dir, 'product_cache.json'), object: true, circular: true)
    end
  end
end
