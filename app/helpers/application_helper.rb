module ApplicationHelper
  
  def get_supported_carriers
    {""=>"", "AusPost" => "Australia Post", "Private_FABUSA" => "Custom Rules - FABUSA"}
  end
  
  
  # return the version of theme currently deployed
  def current_deployed_version
    3
  end
  
end
