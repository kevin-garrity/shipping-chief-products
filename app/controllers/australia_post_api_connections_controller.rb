class AustraliaPostApiConnectionsController < ApplicationController
  # GET /australia_post_api_connections
  # GET /australia_post_api_connections.json
  def index
    @australia_post_api_connections = AustraliaPostApiConnection.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @australia_post_api_connections }
    end
  end

  # GET /australia_post_api_connections/1
  # GET /australia_post_api_connections/1.json
  def show
    # @australia_post_api_connection = AustraliaPostApiConnection.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @australia_post_api_connection }
    end
  end

  # GET /australia_post_api_connections/new
  # GET /australia_post_api_connections/new.json
  #
  # Initialize the API connection with dimensions
  #   weight -- should have been received as a param
  #   heigh, length, width -- should be supplied by prefs
  # Perform an API call to get a list of country codes
  # The form we present should contain a list of countries, as well as an option
  #   to enter the postcode instead (for domestic).
  def new
    puts "---------------IN NEW--------------------"
    @weight = params[:weight]
    @blanks = params[:blanks]
    @shop_url = request.headers["HTTP_ORIGIN"].sub(%r{^.*//}, "")

    @australia_post_api_connection = AustraliaPostApiConnection.new(parameters_supplied_by_preferences)
    @australia_post_api_connection.weight = @weight
    @australia_post_api_connection.blanks = @blanks

    # get country list from the API
   # @countries = @australia_post_api_connection.data_oriented_methods(:country)

    # format the response how we like it
   # @countries = @countries[1]['country'].inject([]) do |list, country|
  #    list.append([country['name'].capitalize, country['code'].capitalize])
  #    list
  #  end

  #  @countries.prepend([ "Australia", "AUS" ])
  @countries = get_country_list(@australia_post_api_connection)

    respond_to do |format|
      puts "---------------About to format--------------------"
      format.html { render layout: false } # new.html.erb 
      format.json { render json: @australia_post_api_connection }
    end
  end

  # GET /australia_post_api_connections/1/edit
  def edit
    @australia_post_api_connection = AustraliaPostApiConnection.find(params[:id])
  end

  # POST /australia_post_api_connections
  # POST /australia_post_api_connections.json
  def create
    puts "---------------IN CREATE------------"
    # merge the raw post data into the params
    params.merge!(Rack::Utils.parse_nested_query(request.raw_post))

    @url = params[:australia_post_api_connection][:shop]

    #try to find the shop preference using shop_url
    @preference = Preference.find_by_shop_url(@url)

    #TODO
    #raise error if @preference.nil?

    # recalculate the weight to include blanks
    calculated_weight = params[:australia_post_api_connection][:blanks].to_i * @preference.default_weight.to_f
    calculated_weight += params[:australia_post_api_connection][:weight].to_f
    params[:australia_post_api_connection][:blanks] = '0'
    params[:australia_post_api_connection][:weight] = calculated_weight.to_s

    @australia_post_api_connection = AustraliaPostApiConnection.new({:weight=> params[:australia_post_api_connection][:weight],
                                                                    :blanks => params[:australia_post_api_connection][:blanks],
                                                                    :from_postcode => @preference.origin_postal_code,
                                                                    :country_code => params[:australia_post_api_connection][:country_code],
                                                                    :to_postcode => params[:australia_post_api_connection][:to_postcode],
                                                                    :height=>@preference.height, :width=>@preference.width, :length=>@preference.length
                                                                     })

    @australia_post_api_connection.domestic = ( @australia_post_api_connection.country_code == "AUS" )

    # get country list from the API -- we'll format these if there were no errors
    @service_list = @australia_post_api_connection.data_oriented_methods(:service) # get the service list

    if @australia_post_api_connection.domestic
      shipping_methods = @preference.shipping_methods_allowed_dom
      shipping_desc = @preference.shipping_methods_desc_dom
    else
      shipping_methods = @preference.shipping_methods_allowed_int
      shipping_desc = @preference.shipping_methods_desc_int
    end

    respond_to do |format|
      if @australia_post_api_connection.save

        @countries = get_country_list(@australia_post_api_connection)
        # TODO right now we are not including the suboptions for each shipping type
        #filter out unwanted methods more efficiently?

        @service_list = Array.wrap( @service_list[1]['service'] ).inject([]) do |list, service|
          puts("service code is " + service['code'])
          if shipping_methods[service['code']]
            price_to_charge = service['price'].to_f
            shipping_name = shipping_desc[service['code']].blank? ? service['name'] : shipping_desc[service['code']]
            unless @preference.nil?
              if @preference.surchange_percentage > 0.0
                price_to_charge =(price_to_charge * (1 + @preference.surchange_percentage/100)).round(2)
              end
            end

            list.append({ name: shipping_name,
                        code: service['code'],
                        price: price_to_charge})
          end
          list
        end

        # we won't do this stuff since we are doing ajax instead?
        # format.html { render action: "new", layout: false }
        # format.json { render json: @australia_post_api_connection, status: :created, location: @australia_post_api_connection }

        # we'll render create.haml
        format.js { render content_type: 'text/html', layout: false }
        format.html { render content_type: 'text/html', layout: false }
      else

        # format.html { render action: "new" }
        # format.json { render json: @australia_post_api_connection.errors, status: :unprocessable_entity }
        format.html { render partial: "trouble", status: 400, layout: false }
      end
    end
  end

  # PUT /australia_post_api_connections/1
  # PUT /australia_post_api_connections/1.json
  def update
    @australia_post_api_connection = AustraliaPostApiConnection.find(params[:id])

    respond_to do |format|
      if @australia_post_api_connection.update_attributes(params[:australia_post_api_connection])
        format.html { redirect_to @australia_post_api_connection, notice: 'Australia post api connection was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @australia_post_api_connection.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /australia_post_api_connections/1
  # DELETE /australia_post_api_connections/1.json
  def destroy
    @australia_post_api_connection = AustraliaPostApiConnection.find(params[:id])
    @australia_post_api_connection.destroy

    respond_to do |format|
      format.html { redirect_to australia_post_api_connections_url }
      format.json { head :no_content }
    end
  end

  private

  def parameters_supplied_by_preferences
    @preference = Preference.find_by_shop_url(@shop_url)

    {
      from_postcode: @preference.origin_postal_code,
      height: @preference.height,
      width: @preference.width,
      length: @preference.length
    }
  end
  
  def get_country_list(api_connection)
    #see if list exist in cache
    if Rails.cache.exist?("aus_post_country_list")
      list =  Rails.cache.read("aus_post_country_list")
    end
    if list.nil?
      # get country list from the API
      countries = api_connection.data_oriented_methods(:country)      
      
      countries = countries[1]['country'].inject([]) do |country_list, country|
        country_list.append([country['name'].capitalize, country['code'].capitalize])
        country_list
      end

      countries.prepend([ "Australia", "AUS" ])
        
      list = countries
      
      Rails.cache.write('aus_post_country_list', countries, :timeToLive => 300.days)
    end
    list
  end

end
