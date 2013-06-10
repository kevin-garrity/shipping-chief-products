require 'oj'

# TODO: this can go away after move the shopify api extensions out of product cache
ProductCache.instance 

class ProductCacheStub
  include ShippingHelpers

  attr_accessor :fixture
  def initialize(fixture)
    fixture = fixture.blank? ? '' : "#{fixture}_"
    @fixture = "#{fixture}product_cache.json"
  end

  def variants
    @variants ||= Oj.load_file(File.join(fixtures_dir, fixture), object: true, circular: true)
  end

  def product_types
    @product_types ||= variants.values.map{|v| v.product.product_type}.uniq.sort
  end

  def write_json(load_cache=false)
    if load_cache
      ProductCache.instance.prime!
      h = ProductCache.instance.variants
    else
      h = @variants
    end
    json = Oj.dump(h, object:true, circular:true)
    save_json(json)
  end

  def save_json(json)
    File.open(File.join(fixtures_dir, fixture), 'w'){|f| f.write(json)}
  end

  def convert!(save=false)
    h = variants
    new_hash = {}
    h.each do |k, v|
      v.instance_variable_set(:@metafields_cached, [])
      v.product.instance_variable_set(:@metafields_cached, [])
      yield v if block_given?
      new_hash[v.id.to_s] = v
    end
    @variants = new_hash
    json = Oj.dump(new_hash, object:true, circular:true)
    if save
      save_json(json)
    end
    json
  end


  def convert_lifemap!(save=false)
    convert!(save) do |v|
      if v.product.vendor == 'ProSpec'
        mefi = ::ShopifyAPI::Metafield.new({
          namespace: 'wby.ship.lifemap', 
          key: 'refrigeration',
          value_type: 'string'
        })
        if (v.product.id % 10) < 3
          mefi.value = 'ice-packs'
        else
          mefi.value = 'lyophilized'
        end
        v.metafields_cached << mefi
      end
    end
  end

end


module CellsProductFixture
  class << self
    include ShippingHelpers
    def product_types
    {
    "Media Kit" => {
      'EM-1001' => {
        price: 1000,
        weight: 1
      },
      'EM-1002' => {
        price: 1200,
        weight: 1.3
      },
      'EM-1003' => {
        price: 1300,
        weight: 1.4
      }
    },
    "Cell" => {
      "C-100" => {
        price: 2000,
        weight: 1
      },
      "C-200" => {
        price: 2100,
        weight: 1
      }
    },
    "Medium" => {
      'ME-1101' => {
        price: 1000,
        weight: 1
      },
      'ME-1102' => {
        price: 1200,
        weight: 1.3
      },
      'ME-1103' => {
        price: 1300,
        weight: 1.4
      }
    },
    "Differentiation Kit" => {
      'DK-100' => {
        price: 1000,
        weight: 1
      },
      'DK-102' => {
        price: 1200,
        weight: 1.3
      },
      'DK-103' => {
        price: 1300,
        weight: 1.4
      }
    },
    "Glycosan Kit" => {
      'GK-100' => {
        price: 400,
        weight: 1
      },
      'GK-102' => {
        price: 430,
        weight: 1
      },
      'GK-103' => {
        price: 440,
        weight: 1
      }
    }

  }
    end

    def write_json(fixture)
      h = ProductCache.instance.variants
      json = Oj.dump(h, object:true, circular:true)
      File.open(File.join(fixtures_dir, "#{fixture}_product_cache.json"), 'w'){|f| f.write(json)}
    end
    def create!
      product_types.each do |t, prods|
        prods.each do |sku, attrs|
          puts "sku: #{sku.inspect}"
          puts "attrs: #{attrs.inspect}"
          ShopifyAPI::Product.create({
            title: "The #{sku} #{t}",
            product_type: t,
            variants: [
              {
                sku: sku,
                weight: attrs[:weight],
                price: attrs[:price]
              }
            ]
          })
        end
      end
    end
  end
end