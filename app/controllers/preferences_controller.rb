include ApplicationHelper
class PreferencesController < ApplicationController
  around_filter :shopify_session
  before_filter :check_payment

  def show
    @supported_carriers = get_supported_carriers
    
    @preference = Preference.find_by_shop_url(session[:shopify].shop.domain)
    @preference = Preference.new if @preference.nil?

    respond_to do |format|
      format.html { render :action => "edit"}
      format.json { render json: @preference }
    end
  end

  # GET /preference/edit
  def edit
    @supported_carriers = get_supported_carriers

    @preference = get_preference    
  end

  # PUT /preference
  # PUT /preference
  def update
    @supported_carriers = get_supported_carriers
    
    @preference = get_preference()

    @preference.shop_url = session[:shopify].shop.domain

    respond_to do |format|
      @preference.attributes = params[:preference]
      
      if (@preference.carrier == "AusPost")
        @preference.shipping_methods_allowed_int = params[:shipping_methods_int]
        @preference.shipping_methods_allowed_dom = params[:shipping_methods_dom]
        @preference.shipping_methods_desc_dom = params[:shipping_methods_desc_dom]
        @preference.shipping_methods_desc_int = params[:shipping_methods_desc_int]
      end
      
      if @preference.save
        #store default charge in shop metafields
        if (@preference.carrier == "AusPost")
          update_shop_metafield(@preference.default_charge)          
          check_shipping_product_exists
          check_shopify_files_present
        elsif (@preference.carrier == "Fedex")
          register_custom_shipping_service
        end
        format.html { redirect_to preferences_url, notice: 'Preference was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @preference.errors, status: :unprocessable_entity }
      end
    end
  end
  
  def carrier_selected
    @preference = get_preference
    
    puts("preference is " + @preference.to_s)
    if (params[:carrier].blank?)
      render :text => ""
    else
      render :partial => params[:carrier].downcase + "_form" 
    end
  end

  def hide_welcome_note
    @preference = Preference.find_by_shop_url(session[:shopify].shop.domain)
    @preference.hide_welcome_note = true
    @preference.save
    render :json =>{:result => "ok"}
  end

  private

  def get_preference
    preference = Preference.find_by_shop_url(session[:shopify].shop.domain)    
    preference = Preference.new if preference.nil?    
    
    preference
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
          asset = ShopifyAPI::Asset.find(asset_file, :params => { :theme_id => t.id})
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

  def register_custom_shipping_service
    
    url = session[:shopify].url
    
    #set up carrier services
    
    if (Rails.env == "production")
      params = {
        "name" => "Webify Custom Shipping Service",
        "callback_url" => "http://foldaboxusa.herokuapp.com/shipping-rates?shop_url="+ url,
        "service_discovery" => false,
        "format" => "json"
      }
    else 
        params = {
          "name" => "Webify Custom Shipping Service Staging",
          "callback_url" => "http://shipping-staging.herokuapp.com/shipping-rates?shop_url="+ url,
          "service_discovery" => false,
          "format" => "json"
        }     
      
    end

    services = ShopifyAPI::CarrierService.find(:all, params => {:"name"=>"Webify Custom Shipping Service"})
    #ShopifyAPI::CarrierService.delete(s[0].id)

    if (services.length == 0)
      carrier_service = ShopifyAPI::CarrierService.create(params)
      logger.debug("Error is " + carrier_service.errors.to_s) if carrier_service.errors.size > 0
    else
 
      ShopifyAPI::CarrierService.delete(services[0].id)
      carrier_service = ShopifyAPI::CarrierService.create(params)
      logger.debug("Readding Error is " + carrier_service.errors.to_s) if carrier_service.errors.size > 0
    end

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

  def update_shop_metafield(default_charge)
    shop = session[:shopify].shop
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
  
  private
  
  def current_deployed_version
    2
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
  
  def upgrade_theme(version, shop)
    if (version == 1)
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
    end
  end
end
