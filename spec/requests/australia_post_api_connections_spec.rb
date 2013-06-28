require 'spec_helper'

describe "AustraliaPostApiConnections" do
  describe "GET /australia_post_api_connections" do
    it "works! (now write some real specs)" do
      pending("refactoring aus post with carriers")

      # Run the generator again with the --webrat flag if you want to use webrat methods/matchers
      get australia_post_api_connections_path
      response.status.should be(200)
    end
  end
end
