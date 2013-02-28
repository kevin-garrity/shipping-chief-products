class PreferencesController < ApplicationController
  around_filter :shopify_session
  before_filter :check_payment

  def show
    check_shipping_product_exists
    check_shopify_files_present
    @preference = Preference.find_by_shop_url(session[:shopify].shop.domain)
    @preference = Preference.new if @preference.nil?

    respond_to do |format|
      format.html { render :action => "edit"}
      format.json { render json: @preference }
    end
  end

  # GET /preference/edit
  def edit
    check_shipping_product_exists
    check_shopify_files_present

    begin
    @preference = Preference.find_by_shop_url(session[:shopify].shop.domain)
    rescue Preference::UnknownShopError => e
      puts 'in edit ' + e.message
      @preference = Preference.new if @preference.nil?
    end

  end

  # PUT /preference
  # PUT /preference
  def update
    begin
      @preference = Preference.find_by_shop_url(session[:shopify].shop.domain)
    rescue Preference::UnknownShopError => e
      puts 'in update ' + e.message
      @preference = Preference.new if @preference.nil?
    end
    @preference = Preference.new if @preference.nil?
    
    @preference.shop_url = session[:shopify].shop.domain

    respond_to do |format|
      @preference.attributes = params[:preference]
      @preference.shipping_methods_allowed_int = params[:shipping_methods_int]
      @preference.shipping_methods_allowed_dom = params[:shipping_methods_dom]
      @preference.shipping_methods_desc_dom = params[:shipping_methods_desc_dom]
      @preference.shipping_methods_desc_int = params[:shipping_methods_desc_int]

      if @preference.save
        #store default charge in shop metafields
        update_shop_metafield(@preference.default_charge)
        format.html { redirect_to preferences_url, notice: 'Preference was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @preference.errors, status: :unprocessable_entity }
      end
    end
  end
  
  def hide_welcome_note
    @preference = Preference.find_by_shop_url(session[:shopify].shop.domain)
    @preference.hide_welcome_note = true
    @preference.save
    render :json =>{:result => "ok"}
  end

  private 

  def check_shopify_files_present    
    url = session[:shopify].url
    shop = Shop.find_by_url(url)
    return if (shop.theme_modified)
    themes = ShopifyAPI::Theme.find(:all)

    theme = themes.find { |t| t.role == 'main' }
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
    asset_files.each do |asset_file|  
      begin        
        asset = ShopifyAPI::Asset.find(asset_file, :params => { :theme_id => theme.id})
      rescue ActiveResource::ResourceNotFound 
        #add asset
        data = File.read(Dir.pwd + "/shopify_theme_modifications/" + asset_file)
        if (asset_file.include?(".gif"))
          data = Base64.encode64(data)          
          f = ShopifyAPI::Asset.new(
            :key =>asset_file,
            :attachment => data
          )
          f.save!          
        else
          f = ShopifyAPI::Asset.new(
            :key =>asset_file,
            :value => data
          )
          f.save!
        end
      end
    end
    shop.theme_modified = true
    shop.save!

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
end
