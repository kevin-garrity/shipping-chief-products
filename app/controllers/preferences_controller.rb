class PreferencesController < ApplicationController
  around_filter :shopify_session

  def show
    @preference = Preference.find

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @preference }
    end
  end

  # GET /preference/edit
  def edit
    @preference = Preference.find
  end

  # PUT /preference
  # PUT /preference
  def update
    @preference = Preference.find
    
    respond_to do |format|
      if @preference.update_attributes(params[:preference])
        format.html { redirect_to @preference, notice: 'Preference was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @preference.errors, status: :unprocessable_entity }
      end
    end
  end

end
