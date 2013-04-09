module Carriers
  module AusPost
    class Installer < ::Carriers::Installer
      def configure
        @preference.shipping_methods_allowed_int = params[:shipping_methods_int]
        @preference.shipping_methods_allowed_dom = params[:shipping_methods_dom]
        @preference.shipping_methods_desc_dom = params[:shipping_methods_desc_dom]
        @preference.shipping_methods_desc_int = params[:shipping_methods_desc_int]
      end

      def install
        update_shop_metafield(@preference.default_charge)          
        check_shipping_product_exists
        check_shopify_files_present        
      end

      private
      def update_shop_metafield(default_charge)
        fields = shop.metafields
        field = fields.find { |f| f.key == 'default_charge' && f.namespace ='AusPostShipping'}
        if field.nil?
          field = ShopifyAPI::Metafield.new({:namespace =>'AusPostShipping',:key=>'default_charge', :value=>default_charge, :value_type=>'string' })
        else
          field.destroy
          field = ShopifyAPI::Metafield.new({:namespace =>'AusPostShipping',:key=>'default_charge', :value=>default_charge, :value_type=>'string' })
        end
        shop.add_metafield(field)
      end

      def check_shipping_product_exists
        fields = "id,title, handle"
        search_params = {:fields=>fields, :limit => 1, :page=>1}
        search_params = search_params.merge({:handle=>"webify-shipping-app-product"})

        @products = ShopifyAPI::Product.find(:all, :params => search_params)

        if @products.length == 0
          #try to create
          prod = ShopifyAPI::Product.new(
            :title =>"Shipping",
            :handle=>"webify-shipping-app-product",
            :product_type=>"product",
            :variants => ShopifyAPI::Variant.new(:price => 0.01)
          )
          prod.save!
        else
          prod = @products[0]
        end

        @vars = ShopifyAPI::Variant.find(:all, :params=>{:product_id => prod.id})

        #save product id in shop metafield for liquid template to consume
        shop = session[:shopify].shop


        if (@vars.length > 0)
          fields = shop.metafields
          field = fields.find { |f| f.key == 'product_id' && f.namespace ='AusPostShipping'}

          if field.nil?
            field = ShopifyAPI::Metafield.new({:namespace =>'AusPostShipping',:key=>'product_id', :value=>@vars[0].id, :value_type=>'string' })
            field.save
          elsif (field.value.to_s != @vars[0].id.to_s) #only save if variant id has changed
            field.destroy
            field = ShopifyAPI::Metafield.new({:namespace =>'AusPostShipping',:key=>'product_id', :value=>@vars[0].id, :value_type=>'string' })
            field.save!
          end
        end

      end

      def check_shopify_files_present
        url = session[:shopify].url
        shop = Shop.find_by_url(url)
        if (shop.theme_modified)      
          #check if need to upgrade theme files

          if (shop.version != current_deployed_version)
            upgrade_theme(shop.version, shop)
          end
          return
        end
        
        #first installation
        
        themes = ShopifyAPI::Theme.find(:all)

        theme = themes.find { |t| t.role == 'main' }

        mobile_theme = themes.find { |t| t.role == 'mobile' }


        asset_files = [
          "assets/webify.consolelog.js",
          "assets/webify_inject_shipping_calculator.js.liquid",
          "assets/webify.ajaxify-shop.js",
          "assets/webify.api.jquery.js",
          "assets/webify.xdr.js.liquid",
          "assets/webify.jquery.cookie.js",
          "assets/checkout.css.liquid",
          "assets/webify_update_loader_and_submit.js.liquid",
          "assets/webify-ajax-loader.gif",
          "snippets/webify-request-shipping-form.liquid",
          "snippets/webify-add-to-cart.liquid",
          "snippets/webify-shipping-items-hidden-price.liquid"
        ]

        themes = Array.new

        themes << theme
        themes <<  mobile_theme unless mobile_theme.nil?

        themes.each do |t|
          asset_files.each do |asset_file|
            begin
              ShopifyAPI::Asset.find(asset_file, :params => { :theme_id => t.id})
            rescue ActiveResource::ResourceNotFound
              #add asset
              data = File.read(Dir.pwd + "/shopify_theme_modifications/" + asset_file)
              if (asset_file.include?(".gif"))
                data = Base64.encode64(data)
                f = ShopifyAPI::Asset.new(
                  :key =>asset_file,
                  :attachment => data,
                  :theme_id => t.id
                )
                f.save!
              else
                f = ShopifyAPI::Asset.new(
                  :key =>asset_file,
                  :value => data,
                  :theme_id => t.id
                )
                f.save!
              end
            end
          end
        end
        shop.theme_modified = true
        shop.save!

      end

      def upgrade_theme(version, shop)
        if (version == 1 || version.nil?)
          logger.info("upgrading #{shop.url} to version 2")      
          themes = ShopifyAPI::Theme.find(:all)
          theme = themes.find { |t| t.role == 'main' }
          mobile_theme = themes.find { |t| t.role == 'mobile' }
          themes = Array.new
          themes << theme
          themes <<  mobile_theme unless mobile_theme.nil?
          #changes for theme
          asset_files = [
                "assets/webify_inject_shipping_calculator.js.liquid",
                "assets/webify_update_loader_and_submit.js.liquid",
                "snippets/webify-add-to-cart.liquid",
                "assets/webify.api.jquery.js"
              ]
          replace_theme_files(asset_files, themes)
          shop.version = 2
          shop.save!
          version = 2
        end
        if (version == 2)
          logger.info("upgrading #{shop.url} to version 3")
          themes = ShopifyAPI::Theme.find(:all)
          theme = themes.find { |t| t.role == 'main' }
          mobile_theme = themes.find { |t| t.role == 'mobile' }
          themes = Array.new
          themes << theme
          themes <<  mobile_theme unless mobile_theme.nil?
          #changes for theme
          asset_files = [
                "assets/webify_inject_shipping_calculator.js.liquid",
                "assets/webify_update_loader_and_submit.js.liquid",
                "snippets/webify-request-shipping-form.liquid",
              ]
          replace_theme_files(asset_files, themes)
          shop.version = 3
          shop.save!
        end    
      end

      def replace_theme_files(asset_files, themes)
        themes.each do |t|
          asset_files.each do |asset_file|
            asset = ShopifyAPI::Asset.find(asset_file, :params => { :theme_id => t.id})
            #add asset
            data = File.read(Dir.pwd + "/shopify_theme_modifications/" + asset_file)
            logger.info("Repacing " + asset_file)
            if (asset_file.include?(".gif"))
              data = Base64.encode64(data)
              f = ShopifyAPI::Asset.new(
                :key =>asset_file,
                :attachment => data,
                :theme_id => t.id
              )
              f.save!
            else
              f = ShopifyAPI::Asset.new(
                :key =>asset_file,
                :value => data,
                :theme_id => t.id
              )
              f.save!
            end

          end #end each asset_files
        end # end each theme
      end

    end
  end
end
