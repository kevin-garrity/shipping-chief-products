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
end
