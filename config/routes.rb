WorldShippingCalculator::Application.routes.draw do

  match 'util/welcome' => 'util#welcome'
  match 'util' => 'util#index'
  controller :sessions do
    get 'login' => :new
    post 'login' => :create
    get 'auth/shopify/callback' => :show
    delete 'logout' => :destroy
  end
  root :to => 'home#index'
  
  match "help" => 'help#index'
  match "confirm_charge" => "home#confirm_charge"
  

  resource 'preferences', only: [:show, :edit, :update]
  match '/australia_post_api_connections' => 'australia_post_api_connections#new', :via => :get
  resources 'australia_post_api_connections'
  # match '/australia_post_api_connections', :controller => 'australia_post_api_connections', :action => 'options', :constraints => {:method => 'OPTIONS'}
end
