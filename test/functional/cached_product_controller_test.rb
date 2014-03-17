require_relative '../test_helper.rb'


class CachedProductControllerTest < ActionController::TestCase
  fixtures :shops, :preference, :chief_products_preference, :cached_products

  def setup
    s =  shops(:chief_products_test_shop)
    
    session[:shopify] = ShopifyAPI::Session.new(s.domain, '')
    
    
  end
  
  def test_index
   get :index
   assert_response :success
  end
  
end
