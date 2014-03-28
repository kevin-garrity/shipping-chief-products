module Carriers
  module ChiefProducts
    class Installer < ::Carriers::Installer
      def configure(params)
          @preference.shipping_methods_allowed_int = params[:shipping_methods_int]
          @preference.shipping_methods_allowed_dom = params[:shipping_methods_dom]
          @preference.shipping_methods_desc_dom = params[:shipping_methods_desc_dom]
          @preference.shipping_methods_desc_int = params[:shipping_methods_desc_int]
         
          @preference.shipping_methods_long_desc_dom = params[:shipping_methods_long_desc_dom]
          @preference.shipping_methods_long_desc_int = params[:shipping_methods_long_desc_int]
           
          withShopify do
            shopify_api_shop = ShopifyAPI::Shop.current
            field = ShopifyAPI::Metafield.new({:namespace =>'chief_products',:key=>'ego_explanation', :value=>params[:carrier_preference][:ego_explanation].to_s, :value_type=>'string' })
            shopify_api_shop.add_metafield(field)
            
            field = ShopifyAPI::Metafield.new({:namespace =>'chief_products',:key=>'aus_post_explanation', :value=>params[:carrier_preference][:aus_post_explanation].to_s, :value_type=>'string' })
            shopify_api_shop.add_metafield(field)
            
            @preference.shipping_methods_long_desc_int.each do |method_name, value|
              
              m = find_metafield(shopify_api_shop, method_name)                          
            
              if m.nil? #not found                
                field = ShopifyAPI::Metafield.new({:namespace =>'chief_products',:key=>method_name, :value=>value.to_s, :value_type=>'string' })
                shopify_api_shop.add_metafield(field)
              else
                if m.value != value
                  m.value = value
                  m.save!
                end
              end
            end
            
            @preference.shipping_methods_long_desc_dom.each do |method_name, value|
              
              m = find_metafield(shopify_api_shop, method_name)
                          
              if m.nil? #not found                
                field = ShopifyAPI::Metafield.new({:namespace =>'chief_products',:key=>method_name, :value=>value.to_s, :value_type=>'string' })
                shopify_api_shop.add_metafield(field)
              else
                if m.value != value
                  m.value = value
                  m.save!
                end
              end
            end
                        
          end #end withShopify
          
      end
      
      def find_metafield(shopify_api_shop, method_name)
        shopify_api_shop.metafields.each do |metafield|
          if metafield.key.to_s.include?(method_name)
            m = metafield
            return m         
          end                  
        end
        
        return nil          
      end

      def install
        Rails.logger.info("#{self.class.name}#install")
        register_custom_shipping_service
      end      
    end    
  end
end
