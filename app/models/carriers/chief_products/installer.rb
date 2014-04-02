module Carriers
  module ChiefProducts
    class Installer < ::Carriers::Installer
      
      def find_or_create_metafield(shopify_api_shop, key_name, field_value)
        found = shopify_api_shop.metafields.select {|m| m.key == key_name}            
        if (found.length > 0)
          if (found[0].value.to_s != field_value)
            found[0].value = field_value
            found[0].save!
          end                       
        else
          field = ShopifyAPI::Metafield.new({:namespace =>'chief_products',:key=>key_name, :value=>field_value, :value_type=>'string' })
          shopify_api_shop.add_metafield(field)
        end
      end
      
      def configure(params)
          @preference.shipping_methods_allowed_int = params[:shipping_methods_int]
          @preference.shipping_methods_allowed_dom = params[:shipping_methods_dom]
          @preference.shipping_methods_desc_dom = params[:shipping_methods_desc_dom]
          @preference.shipping_methods_desc_int = params[:shipping_methods_desc_int]
         
          @preference.shipping_methods_long_desc_dom = params[:shipping_methods_long_desc_dom]
          @preference.shipping_methods_long_desc_int = params[:shipping_methods_long_desc_int]
           
          withShopify do
            shopify_api_shop = ShopifyAPI::Shop.current
            
            find_or_create_metafield(shopify_api_shop, 'ego_explanation', params[:carrier_preference][:ego_explanation].to_s)
            find_or_create_metafield(shopify_api_shop, 'aus_post_explanation', params[:carrier_preference][:aus_post_explanation].to_s)
            find_or_create_metafield(shopify_api_shop, 'rate_lookup_error', params[:carrier_preference][:rate_lookup_error].to_s)
                                     
            
            @preference.shipping_methods_long_desc_int.each do |method_name, value|              
              find_or_create_metafield(shopify_api_shop, method_name, value.to_s)                       
            end
            
            @preference.shipping_methods_long_desc_dom.each do |method_name, value|
              find_or_create_metafield(shopify_api_shop, method_name, value.to_s)                         
            end
                        
          end #end withShopify
          
      end            

      def install
        Rails.logger.info("#{self.class.name}#install")
        register_custom_shipping_service
      end      
    end    
  end
end
