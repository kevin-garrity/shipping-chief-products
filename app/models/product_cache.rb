=begin
  shopify does not send enough information, so we have to maintain a product cache
=end
require 'logger'

class ProductCache

  attr_accessor :domain, :opts

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

  def product_fields
    opts[:product_fields] || "id,product_type,title,options,variants,vendor"
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
    end
    @products
  end

  def[](shopify_rates_params_item)
    
  end

  def dirty!
    @products = nil
  end

end