BenefitMarkets::Engine.routes.draw do
  resources :sites, only: [] do
    resources :benefit_markets, shallow_nested: true
  end

  resources :benefit_markets, only: [:new, :create, :show, :edit, :update] do
    resource :configuration
  end

  namespace :products do
    resources :product_packages, :only => [:new, :create, :show, :edit, :update]
  end
end
