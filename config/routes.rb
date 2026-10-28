Rails.application.routes.draw do
  devise_for :usuarios
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "home#index"

  get "home", to: "home#index"
  get "perfil", to: "usuario#show", as: :perfil
  patch "perfil", to: "usuario#update"
  get "admin", to: "admin#index"
  get "admin/perfil", to: "admin#show", as: :admin_perfil
  get "decants/masculinos", to: "produto#decants_masculinos", as: :decants_masculinos
  get "decants/femininos",  to: "produto#decants_femininos",  as: :decants_femininos
  get "produtos_todos", to: "produto#pag_todos_prod", as: :produtos_todos
  get "busca", to: "produto#busca", as: :busca
  get "busca/sugestoes", to: "produto#sugestoes", as: :busca_sugestoes

  resources :produtos, controller: "produto", only: [:index, :show, :new, :create, :edit, :update, :destroy] # rubocop:disable Layout/SpaceInsideArrayLiteralBrackets
  resources :frasco_maes, controller: "frasco_mae", except: [:show] # rubocop:disable Layout/SpaceInsideArrayLiteralBrackets

  namespace :admin do
    root to: 'dashboard#index'
    resources :pedidos, only: [:index]
  end
end
