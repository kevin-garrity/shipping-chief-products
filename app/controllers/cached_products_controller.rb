class CachedProductsController < ActionController::Base


  def index
    
    search_params = {:fields=>"id", :limit => false}
    
    count = ShopifyAPI::Product.count(search_params)        

    Rails.logger.debug "Count: #{count}"

    page_size = 10
    @total_page = count / page_size
    @total_page = @total_page + 1 if (count % page_size > 0)
   
    @page = 1 if (@page.to_i > @total_page.to_i)

    fields = "id,title,images,options,variants"

    search_params = {:fields=>fields, :limit => page_size, :page=>@page}      
    # ppl search_params
    @products = ShopifyAPI::Product.find(:all, :params => search_params)
    # ppl @product
    
    @cached_products = CachedProducts.find_by_shop_id(current_shop.id)
    
    # see if there is any new products to be added
    
  end
  
  def update_list
  end
end