require "spec_helper"

describe AustraliaPostApiConnectionsController do
  describe "routing" do

    it "routes to #index" do
      get("/australia_post_api_connections").should route_to("australia_post_api_connections#index")
    end

    it "routes to #new" do
      get("/australia_post_api_connections/new").should route_to("australia_post_api_connections#new")
    end

    it "routes to #show" do
      get("/australia_post_api_connections/1").should route_to("australia_post_api_connections#show", :id => "1")
    end

    it "routes to #edit" do
      get("/australia_post_api_connections/1/edit").should route_to("australia_post_api_connections#edit", :id => "1")
    end

    it "routes to #create" do
      post("/australia_post_api_connections").should route_to("australia_post_api_connections#create")
    end

    it "routes to #update" do
      put("/australia_post_api_connections/1").should route_to("australia_post_api_connections#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/australia_post_api_connections/1").should route_to("australia_post_api_connections#destroy", :id => "1")
    end

  end
end
