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
    @australia_post_api_connection = AustraliaPostApiConnection.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @australia_post_api_connection }
    end
  end

  # GET /australia_post_api_connections/new
  # GET /australia_post_api_connections/new.json
  def new
    @australia_post_api_connection = AustraliaPostApiConnection.new

    respond_to do |format|
      format.html # new.html.erb
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
    @australia_post_api_connection = AustraliaPostApiConnection.new(params[:australia_post_api_connection])

    respond_to do |format|
      if @australia_post_api_connection.save
        format.html { redirect_to @australia_post_api_connection, notice: 'Australia post api connection was successfully created.' }
        format.json { render json: @australia_post_api_connection, status: :created, location: @australia_post_api_connection }
      else
        format.html { render action: "new" }
        format.json { render json: @australia_post_api_connection.errors, status: :unprocessable_entity }
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
end
