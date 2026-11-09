Rails.application.routes.draw do
  devise_for :usuarios, controllers: {
  registrations: "usuarios/registrations"
}
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
  get "admin", to: "admin#index", as: :admin
  get "admin/perfil", to: "admin#show", as: :admin_perfil
  get "decants/masculinos", to: "produto#decants_masculinos", as: :decants_masculinos
  get "decants/femininos",  to: "produto#decants_femininos",  as: :decants_femininos
  get "produtos_todos", to: "produto#pag_todos_prod", as: :produtos_todos
  get "busca", to: "produto#busca", as: :busca
  get "busca/sugestoes", to: "produto#sugestoes", as: :busca_sugestoes

  resources :produtos, controller: "produto", only: [:index, :show, :new, :create, :edit, :update, :destroy] # rubocop:disable Layout/SpaceInsideArrayLiteralBrackets
  resources :mensagens, only: [:new, :create]
  resources :frasco_maes, controller: "frasco_mae", except: [:show] # rubocop:disable Layout/SpaceInsideArrayLiteralBrackets

  namespace :admin do
    resources :pedidos, only: [:index, :show]
    resources :mensagens, only: [:index, :show, :destroy]
    get "customizar", to: "customizar#index", as: :customizar
    patch "customizar/:id", to: "customizar#update", as: :atualizar_banner
    get "analisar", to: "analisar#index", as: :analisar
    get "configuracoes", to: "configuracoes#index", as: :configuracoes
    patch "configuracoes", to: "configuracoes#update"
  end

  resource :carrinho, only: [:show], controller: "carrinho" do
    post "adicionar", to: "itens_carrinho#create", as: :adicionar
    post "finalizar", to: "carrinho#finalizar", as: :finalizar
    delete "limpar", to: "carrinho#limpar", as: :limpar
  end

  resources :itens_carrinho, only: [:update, :destroy]
  
end
