class HomeController < ApplicationController
  
  around_filter :shopify_session, :except => 'welcome'
  
  def welcome
    current_host = "#{request.host}#{':' + request.port.to_s if request.port != 80}"
    @callback_url = "http://#{current_host}/login"
  end
  
def index
      @page = 1
      @page = params[:page] unless (params[:page].blank?)
      
      collection_term = params[:search_collect]
      collection_term = "" if (collection_term == "0") #all products
        
      product_name = params[:product_name]
      
      @cust_collections = get_collections
      @selected_collection = collection_term

      @filter_note="Note: Only a maximum of 250 products can be displayed due to Shopify API limitation"
      
      search_params = {:fields=>"id", :limit => 250}
      search_params = search_params.merge({:collection_id=>collection_term}) unless collection_term.blank?
      search_params = search_params.merge({:handle=>product_name.parameterize}) unless product_name.blank?

      all_products = ShopifyAPI::Product.find(:all, :params => search_params)        

      count = all_products.size
    
      page_size = 3 # magic
      @total_page = count / page_size
      @total_page = @total_page + 1 if (count % page_size > 0)
       
      @page = 1 if (@page.to_i > @total_page.to_i)
    
      search_params = {:fields=>"id,title,images", :limit => page_size, :page=>@page}      
      search_params = search_params.merge({:collection_id=>collection_term}) unless collection_term.blank?
      search_params = search_params.merge({:handle=>product_name.parameterize}) unless product_name.blank?

      @products = ShopifyAPI::Product.find(:all, :params => search_params)
  end

  def get_collections
     cust_collections = ShopifyAPI::CustomCollection.find(:all)
     smart_collections = ShopifyAPI::SmartCollection.find(:all)
  
     cust_collections.concat smart_collections
     cust_collections    
  end

end