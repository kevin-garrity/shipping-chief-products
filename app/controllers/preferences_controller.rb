class PreferencesController < ApplicationController
  around_filter :shopify_session
  before_filter :check_payment
  
  def show
    @preference = Preference.find_by_shop_url(session[:shopify].shop.domain)
    @preference = Preference.new if @preference.nil?
    
    respond_to do |format|
      format.html { render :action => "edit"}
      format.json { render json: @preference }
    end
  end

  # GET /preference/edit
  def edit
    @preference = Preference.find_by_shop_url(session[:shopify].shop.domain)
    @preference = Preference.new if @preference.nil?
    
  end

  # PUT /preference
  # PUT /preference
  def update
    @preference = Preference.find_by_shop_url(session[:shopify].shop.domain)
    @preference = Preference.new if @preference.nil?
    @preference.shop_url = session[:shopify].shop.domain
  
    respond_to do |format|
       @preference.attributes = params[:preference]
       @preference.shipping_methods_allowed = params[:shipping_methods]
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

private 
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
