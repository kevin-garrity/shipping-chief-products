require 'spec_helper'

describe "Preferences" do
  describe "GET /preferences" do
    it "works! (now write some real specs)" do
      pending("refactoring aus post with carriers")

      # Run the generator again with the --webrat flag if you want to use webrat methods/matchers
      get preferences_path
      response.status.should be(200)
    end
  end
end
