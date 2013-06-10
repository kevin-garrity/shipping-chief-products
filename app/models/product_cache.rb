=begin
  shopify does not send enough information, so we have to maintain a product cache
=end
require 'logger'
require 'dalli'

class ShopifyAPI::Base
  def metafields_cached
    @metafields_cached ||= metafields(namespace: 'wby.ship').map(&:attributes)
  end
  def metafields_cached=(metafields)
  end
end

module ::ShopifyAPI::Metafields
  def metafields(opts={})
    ::ShopifyAPI::Metafield.find(:all, :params => {:resource => self.class.collection_name, :resource_id => id}.merge(opts))
  end
end


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
    ShopifyAPI::Base.site.hostname
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
    @variants ||= begin
      logger.debug "ProductCache#variants - checking cache for variants"
      @variants = cache.get(variants_key)
      logger.debug "  got #{@variants.nil? ? 'nil' : @variants.length}"
      @variants ||= {}
      cache.set(variants_key, @variants)
      @variants
    end
  end

  def products
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

  def [](shopify_rates_params_item)
    variant_id = shopify_rates_params_item['variant_id'].to_s
    product_id = shopify_rates_params_item['product_id'].to_s
    variant = self.variants[variant_id]
    if variant.nil?
      puts "   couldn't find #{variant_id} in cache(#{self.variants.length})"
      pp self.variants.keys
      product = throttle(false){ ShopifyAPI::Product.find(product_id) }
      variant = product.variants.detect{|v| v.id.to_s == variant_id}
      variant ||= throttle{ ShopifyAPI::Variant.find(variant_id)}
      throttle{ variant.metafields_cached }
      throttle{ product.metafields_cached }
      # product = product.attributes
      product.attributes.delete(:variants)
      # variant = variant.attributes
      variant.product = product
      self.variants[variant_id] = variant
      puts "updating cache with:"
      pp @variants
      cache.set(variants_key, @variants)
      puts "now cache:"
      pp cache.get(variants_key)
    end
    variant
  end

  def prime!
    products = throttle{ ShopifyAPI::Product.find(:all,
      params: {limit: false, fields: product_fields}
      ) }
    @variants = {}
    products.each do |product|
      throttle{ product.variants }
      throttle{ product.metafields_cached }
      product.variants.each do |variant|
        throttle{ variant.metafields_cached }
        variant.attributes[:product] = product
        @variants[variant.id.to_s] = variant
      end
      cache.set(variants_key, @variants)
      @variants
    end
  end

  def throttle(presleep=true, &block)
    begin
      if presleep && ShopifyAPI.credit_left < 10
        sleep(10 - ShopifyAPI.credit_left)
      end
      yield
    rescue ActiveResource::ServerError
      presleep = false
      Rails.logger.debug "hit the Shopify API call limit, sleeping for 12 seconds"
      sleep 15
      retry
    end
  end

  def dirty!(product_id=nil)
    @variants = nil
    cache.delete(variants_key)
    @products = nil
    cache.delete(products_key)
    @domain = nil
  end

  def resources_for_rates_query(rates_query, time_allowed)
    items = rates_query['items'].dup

    items.each do |item|
      item['prod_req'] = Shydra::Request.new(
        :product, id: item['product_id'],fields: product_fields)
      item['prod_meta_req'] = Shydra::Request.new(
        :metafields)
    end
  end

  def product_ids_in_order(items)
    Set.new(items.map{|i| i[:product_id]})
  end
  
  def variant_ids_in_order(items)
    Set.new(items.map{|i| i[:variant_id]})
  end
  
  def variants_for_order(items)
    shydra = Shydra::Hydra.new
    order_p = product_ids_in_order(items)
  end


end
