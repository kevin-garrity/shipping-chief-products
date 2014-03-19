class CachedProductController < ApplicationController  
  include ApplicationHelper
  include CarrierHelper

  around_filter :shopify_session
  
  layout "application-no-left"
  
  def index
    
    @shop = current_shop
    
    @cached_products = CachedProduct.find_all_by_shop_id(@shop.id, order: "product_id")
    
    size = 0 if @cached_products.nil?
    size = @cached_products.length unless @cached_products.nil?
      
    # see if there is any new products to be added
    if size == 0
      @shopify_products = update_list 
      @cached_products = @shopify_products.collect {|p| CachedProduct.new(product_id: p.id, shop_id:current_shop.id,product_name: p.title)}
      
      @cached_products.each do |p|
        p.save!
      end
    end    
  end
  
  def load_new_products
    @shop = current_shop
    
    @shopify_products = update_list 
    
    #see if there is any new product in @shopify_products
    @shopify_products.each do |sp|
      cp = CachedProduct.find_by_product_id(sp.id)
      if cp.nil?
        p = CachedProduct.new(product_id: sp.id, shop_id:current_shop.id,product_name: sp.title)
        p.save!
      end
    end
    
  end
  
  def update_all
    @shop = current_shop    
    @cached_products = params[:cached_products]
    @cached_products.each do |p|
      id = p[1][:id]
      product = CachedProduct.find(id)
      unless product.nil?
        product.product_id = p[1][:product_id]
        product.shop_id = p[1][:shop_id]
        product.height = p[1][:height]
        product.width = p[1][:width]
        product.length = p[1][:length]
        product.save
      end
    end
    flash[:notice] = "saved"
    redirect_to :action=> :index
  end
  
  def update_list
    search_params = {:fields=>"id", :limit => false}

    count = ShopifyAPI::Product.count(search_params)        

    page_size = 250
    @total_page = count / page_size
    @total_page = @total_page + 1 if (count % page_size > 0)

    @page = 1 if (@page.to_i > @total_page.to_i)

    fields = "id,title,images,options,variants"

    search_params = {:fields=>fields, :limit => page_size, :page=>@page}      
    # ppl search_params
    @products = ShopifyAPI::Product.find(:all, :params => search_params)
    # ppl @product
  end
end