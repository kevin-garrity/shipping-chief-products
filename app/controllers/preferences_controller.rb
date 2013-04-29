class PreferencesController < ApplicationController
  include ApplicationHelper
  include CarrierHelper

  around_filter :shopify_session
  before_filter :check_payment

  def show
    @preference = get_preference
    installer_class = carrier_installer_class_for(@preference.carrier)
    installer = installer_class.new( session[:shopify].shop, @preference)
    installer.port = request.port if Rails.env.development?
    installer.configure
    installer.install

    Rails.logger.info("session[:shopify].url: #{session[:shopify].url.inspect}")
    respond_to do |format|
      format.html { render :action => "edit"}
      format.json { render json: @preference }
    end
  end

  # GET /preference/edit
  def edit
    @preference = get_preference    
  end

  # PUT /preference
  # PUT /preference
  def update
    
    @preference = get_preference()

    @preference.shop_url = session[:shopify].shop.domain

    respond_to do |format|
      @preference.attributes = params[:preference]

      installer_class = carrier_installer_class_for(@preference.carrier)
      installer = installer_class.new( session[:shopify].shop, @preference)
      installer.port = request.port if Rails.env.development?
      installer.configure

      if @preference.save
        installer.install

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
      render :partial => carrier_partial_for( params[:carrier] )
    end
  end

  def hide_welcome_note
    @preference = get_preference
    @preference.hide_welcome_note = true
    @preference.save
    render :json =>{:result => "ok"}
  end

  private

  def get_preference
    preference = Preference.find_by_shop(current_shop)    
    preference ||= Preference.new
  end
  

end
