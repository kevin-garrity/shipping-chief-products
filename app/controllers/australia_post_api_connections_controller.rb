class AustraliaPostApiConnectionsController < ApplicationController

  # GET /australia_post_api_connections/new
  # GET /australia_post_api_connections/new.json
  def new
    @weight = params[:weight]
    @blanks = params[:blanks]
    @items = params[:items]
    shop_url = request.headers["HTTP_ORIGIN"].sub(%r{^.*//}, "")

    preference = Preference.find_by_shop_url!(shop_url)

    @australia_post_api_connection = AustraliaPostApiConnection.new({
      from_postcode: preference.origin_postal_code,
      height: preference.height,
      width: preference.width,
      length: preference.length
    })

    @australia_post_api_connection.weight = @weight
    @australia_post_api_connection.blanks = @blanks
    @australia_post_api_connection.items = @items
    
    @countries = get_country_list(@australia_post_api_connection)

    respond_to do |format|
      format.html { render layout: false } # new.html.erb 
      format.json { render json: @australia_post_api_connection }
    end
  end

  # POST /australia_post_api_connections
  # POST /australia_post_api_connections.json
  def create

    # merge the raw post data into the params
    params.merge!(Rack::Utils.parse_nested_query(request.raw_post))

    url = params[:australia_post_api_connection][:shop]

    #try to find the shop preference using url
    preference = Preference.find_by_shop_url!(url)

    # recalculate the weight to include blanks
    calculated_weight = params[:australia_post_api_connection][:blanks].to_i * preference.default_weight.to_f
    calculated_weight += params[:australia_post_api_connection][:weight].to_f

    items =  params[:australia_post_api_connection][:items]
    
    if (preference.offers_flat_rate)
      if (calculated_weight <= preference.under_weight)
        @service_list = Array.new
        @service_list.append({ name: "Shipping",
                      code: "Shipping",
                      price: preference.flat_rate.to_s})    
        respond_to do |format|        
          format.js { render content_type: 'text/html', layout: false }
          format.html { render content_type: 'text/html', layout: false }                          
        end
        return  #evil...
      end
    end
    
    weight = params[:australia_post_api_connection][:weight]
    
    if (preference.free_shipping_by_collection)
      subtract_weight = 0
      
      #get free shipping items weight and subtract total weight.
      item_array = items.split(',')
      
      app_shop =  Shop.find_by_url(url)
      
      ShopifyAPI::Session.temp(app_shop.myshopify_domain, app_shop.token) do      
        item_array.each do |item|
          variant = ShopifyAPI::VariantWithProduct.find(item)          
          p = ShopifyAPI::Product.find(variant.product_id)
          
          p.collections.each do |col|
            fields = col.metafields
            field = fields.find { |f| f.key == 'free_shipping' && f.namespace ='AusPostShipping'}
            unless field.nil?
              subtract_weight += variant.grams if field.value == "true"            
            end
          end
        
          p.smart_collections.each do |col|
            fields = col.metafields
            field = fields.find { |f| f.key == 'free_shipping' && f.namespace ='AusPostShipping'}
            unless field.nil?
              subtract_weight += variant.grams if field.value == "true"            
            end
          end
        end
      end
      
          
      weight = weight.to_f - subtract_weight/1000
    end


    if (weight.to_f == 0.0)
      #no need to call australia post. no weight of item
       @service_list = Array.new
        @service_list.append({ name: "Free Shipping",
                      code: "Free Shipping",
                      price: "0.0"})    
        respond_to do |format|        
          format.js { render content_type: 'text/html', layout: false }
          format.html { render content_type: 'text/html', layout: false }                          
        end
        return
    else    
      @australia_post_api_connection = AustraliaPostApiConnection.new({:weight=> weight,
                                                                      :blanks => params[:australia_post_api_connection][:blanks],
                                                                      :from_postcode => preference.origin_postal_code,
                                                                      :country_code => params[:australia_post_api_connection][:country_code],
                                                                      :to_postcode => params[:australia_post_api_connection][:to_postcode],
                                                                      :height=>preference.height, :width=>preference.width, :length=>preference.length,
                                                                      :container_weight => preference.container_weight, :items => items
      })
    end
    
    @australia_post_api_connection.domestic = ( @australia_post_api_connection.country_code == "AUS" )

    # get country list from the API -- we'll format these if there were no errors
    @service_list = @australia_post_api_connection.data_oriented_methods(:service) # get the service list

    if @australia_post_api_connection.domestic
      shipping_methods = preference.shipping_methods_allowed_dom
      shipping_desc = preference.shipping_methods_desc_dom
    else
      shipping_methods = preference.shipping_methods_allowed_int
      shipping_desc = preference.shipping_methods_desc_int
    end

    respond_to do |format|
      if @australia_post_api_connection.save

        @countries = get_country_list(@australia_post_api_connection)
        # TODO right now we are not including the suboptions for each shipping type
        #filter out unwanted methods more efficiently?

        @service_list = Array.wrap( @service_list[1]['service'] ).inject([]) do |list, service|
          Rails.logger.debug("service code is " + service['code'])
          if shipping_methods[service['code']]
            price_to_charge = service['price'].to_f
            shipping_name = shipping_desc[service['code']].blank? ? service['name'] : shipping_desc[service['code']]
            unless preference.nil?
              unless preference.surcharge_percentage.nil?
                if preference.surcharge_percentage > 0.0
                  price_to_charge =(price_to_charge * (1 + preference.surcharge_percentage/100)).round(2)
                end
              end

              unless preference.surcharge_amount.nil?
                if preference.surcharge_amount > 0.0
                  price_to_charge = (price_to_charge + preference.surcharge_amount).round(2)
                end
              end
            end

            list.append({ name: shipping_name,
                        code: service['code'],
                        price: price_to_charge})
          end
       
          list
        end

        # check if need to add free shipping option
        if (preference.free_shipping_option)
           @service_list.append({ name: preference.free_shipping_description,
                        code: "Free",
                        price: "0.00"})
        end
        format.js { render content_type: 'text/html', layout: false }
        format.html { render content_type: 'text/html', layout: false }
      else //   if @australia_post_api_connection.save
        # set the flash

        flash.now[:error] = @australia_post_api_connection.api_errors.join(', ')
        # format.html { render action: "new" }
        # format.json { render json: @australia_post_api_connection.errors, status: :unprocessable_entity }
      #  if (flash.now[:error].blank?)
       #   format.html { render :text => "api_error" }
      #  else
          format.html { render partial: "trouble", layout: false }
       # end
      end
    end
  end

  private

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
