module Carriers
  module ChiefProducts
    class Installer < ::Carriers::Installer
      def configure(params)
          @preference.shipping_methods_allowed_int = params[:shipping_methods_int]
          @preference.shipping_methods_allowed_dom = params[:shipping_methods_dom]
          @preference.shipping_methods_desc_dom = params[:shipping_methods_desc_dom]
          @preference.shipping_methods_desc_int = params[:shipping_methods_desc_int]
          
          withShopify do
            shopify_api_shop = ShopifyAPI::Shop.current
            field = ShopifyAPI::Metafield.new({:namespace =>'chief_products',:key=>'ego_explanation', :value=>params[:carrier_preference][:ego_explanation].to_s, :value_type=>'string' })
            shopify_api_shop.add_metafield(field)
            
            field = ShopifyAPI::Metafield.new({:namespace =>'chief_products',:key=>'aus_post_explanation', :value=>params[:carrier_preference][:aus_post_explanation].to_s, :value_type=>'string' })
            shopify_api_shop.add_metafield(field)            
          end
          
      end

      def install
        Rails.logger.info("#{self.class.name}#install")
        register_custom_shipping_service
      end      
    end    
  end
end
