class CachedProductController < ApplicationController  

  def index    
    @cached_products = CachedProduct.find_by_shop_id(current_shop.id)
    
    # see if there is any new products to be added
    if @cached_products.length == 0
      @shopify_products = update_list 
      @cached_products = @shopify_products.collect {|p| CacheProduct.new(product_id: p.id, shop_id:current_shop.id, sku: p.sku)}
    end    
  end
  
  def update_all
  end
  
  def update_list
    search_params = {:fields=>"id", :limit => false}

    count = ShopifyAPI::Product.count(search_params)        

    page_size = 10
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