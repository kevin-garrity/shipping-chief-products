=begin
  shopify does not send enough information, so we have to maintain a product cache
=end
require 'logger'
require 'dalli'

class ProductCache
  include Singleton

  attr_accessor :logger

  def initialize()
    if defined?(Rails)
      @logger = Rails.logger
    else 
      @logger = Logger.new(STDOUT)
    end
  end


  def domain
    @domain ||= ShopifyAPI::Shop.current.myshopify_domain
    @domain
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
    "id,product_type,title,options,variants,vendor"
  end

  def variants
    dirty?
    @variants ||= begin
      logger.debug "ProductCache#variants - checking cache for variants"
      @variants = cache.get(variants_key)
       logger.debug "  got #{@variants.nil? ? 'nil' : @variants.length}"
     @variants ||= begin
       products = ShopifyAPI::Product.find(:all,
          params: {limit: false, fields: product_fields}
        )
        @variants = {}
        products.each do |product|
          product.variants.each do |variant|
            variant.attributes[:product] = product
            item_title = [product.title, variant.title].join(' - ')
            @variants[item_title] = variant
          end
        end
        cache.set(variants_key, @variants)
        @variants
      end
    end
  end

  def products
    dirty?
    @products ||= begin
      logger.debug "ProductCache#products - checking cache for products"
      @products = cache.get(products_key)
      logger.debug "  got #{@products.nil? ? 'nil' : @products.length}"
      @products ||= ShopifyAPI::Product.find(:all,
        params: {limit: false, fields: product_fields}
      )
      cache.set(products_key, @products)
      @products
    end
  end

  def[](shopify_rates_params_item)
    logger.debug('ProductCache[] called')
    variant = self.variants[shopify_rates_params_item['name']]
    if variant.nil?
      variant = ShopifyAPI::Variant.find(shopify_rates_params_item['variant_id'])
      variant.attributes[:product] = ShopifyAPI::Product.find(shopify_rates_params_item['product_id'])
      self.variants[shopify_rates_params_item['name']] = variant
      cache.set(variants_key, @variants)
    end
    variant
  end

  def dirty!
    @variants = nil
    cache.delete(variants_key)
    @products = nil
    cache.delete(products_key)
    @domain = nil
  end

  def dirty?
    if @domain != ShopifyAPI::Shop.current.myshopify_domain
      @domain = ShopifyAPI::Shop.current.myshopify_domain
      @variants = nil
      @products = nil
    end
  end

end