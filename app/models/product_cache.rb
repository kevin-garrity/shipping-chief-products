=begin
  shopify does not send enough information, so we have to maintain a product cache
=end
require 'logger'
require 'dalli'

class ProductCache

  attr_accessor :domain, :opts, :logger

  def initialize(opts={})
    @domain = ShopifyAPI::Shop.current.myshopify_domain
    @opts = opts
    @logger = opts[:logger] || Logger.new(STDOUT)
  end
  
  def cache
    @cache ||= Dalli::Client.new
  end

  def products_key
    "#{domain}-products"
  end

  def variants_key
    "#{domain}-variants"
  end


  def product_fields
    opts[:product_fields] || "id,product_type,title,options,variants,vendor"
  end

  def variants
    @variants ||= begin
      products = ShopifyAPI::Product.find(:all,
        params: {limit: false, fields: product_fields}
      )
      puts "products.map(&:id): #{products.map(&:id).inspect}"
      @variants = {}
      products.each do |product|
        product.variants.each do |variant|
          variant.attributes[:product] = product
          item_title = [product.title, variant.title].join(' - ')
          @variants[item_title] = variant
        end
      end
      @variants
    end
  end

  def products
    @products ||= begin
      logger.debug "checking cache for products"
      @products = cache.get(products_key)
      logger.debug "got #{@products.nil? ? 'nil' : @products.length}"
      @products ||= ShopifyAPI::Product.find(:all,
        params: {limit: false, fields: product_fields}
      )
      cache.set(products_key, @products)
      @products
    end
  end

  def[](shopify_rates_params_item)
    self.variants[shopify_rates_params_item['name']]
  end

  def dirty!
    @variants = nil
  end

end