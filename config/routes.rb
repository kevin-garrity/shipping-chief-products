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
  
  match "/shipping_rates" => "rates#shipping_rates", :via => :post #Consider removing the external
  

  resource 'preferences', only: [:show, :edit, :update]
  match '/preferences/hide_welcome_note' => 'preferences#hide_welcome_note', :via=>[:get, :post]
  
  match '/australia_post_api_connections' => 'australia_post_api_connections#new', :via => :get
  
  match '/webhooks/app/uninstalled' => 'webhooks#uninstall_app', :via => :post
  
  resources 'australia_post_api_connections'
  # match '/australia_post_api_connections', :controller => 'australia_post_api_connections', :action => 'options', :constraints => {:method => 'OPTIONS'}
end
