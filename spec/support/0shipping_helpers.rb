require 'dalli'

begin
  puts "wtf"
  Dalli::Client.new.get('stuff')
rescue
  system "memcached &"
end

module ShippingHelpers
  def fixtures_dir
    File.join(File.dirname(__FILE__), '..', 'fixtures')
  end
end


shared_context "mock shopify" do
  before do
    @preference = double('preference')
    @preference.stub(:shop_url).and_return("test.myshopify.com")
    @mock_shop = double('shop')
    @mock_shop.stub(:myshopify_domain).and_return("test.myshopify.com")
    @mock_shop.stub(:token).and_return("xyz")
    ShopifyAPI::Shop.stub(:current).and_return(@mock_shop)
    ::Shop.stub(:find_by_url).and_return(@mock_shop)
    ShopifyAPI::Session.stub(:temp).and_yield
  end


end
