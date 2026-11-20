Rails.application.routes.draw do
  devise_for :usuarios, controllers: {
  registrations: "usuarios/registrations",
  sessions: "usuarios/sessions",
  passwords: "usuarios/passwords",
  omniauth_callbacks: "usuarios/omniauth_callbacks"
}
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  get "up" => "health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "home#index"
  post "/rails/active_storage/direct_uploads", to: "uploads#create"
  get "fotos/:chave", to: "fotos#show", as: :foto
  get "pedidos/:pedido_id/pagamento", to: "pagamentos#show", as: :pagamento_pedido
  post "pedidos/:pedido_id/pagar", to: "pagamentos#create", as: :pagar_pedido
  post "pagamentos/mercado-pago/notificacoes", to: "webhooks/mercado_pago#create", as: :mercado_pago_webhook

  get "quiz", to: "quiz#new", as: :quiz
  post "quiz", to: "quiz#create"
  get "quiz/resultado", to: "quiz#resultado", as: :resultado_quiz
  get "perguntas-frequentes", to: "paginas#perguntas_frequentes", as: :perguntas_frequentes
  get "trocas-e-devolucoes", to: "paginas#trocas", as: :trocas
  get "privacidade", to: "paginas#privacidade", as: :privacidade
  get "sobre", to: "paginas#sobre", as: :sobre
  get "atendimento", to: "paginas#atendimento", as: :atendimento
  get "grupo-vip", to: "paginas#grupo_vip", as: :grupo_vip

  get "home", to: "home#index"
  get "perfil", to: "usuario#show", as: :perfil
  patch "perfil", to: "usuario#update"
  get "admin", to: "admin#index", as: :admin
  get "admin/perfil", to: "admin#show", as: :admin_perfil
  get "decants/masculinos", to: "produto#decants_masculinos", as: :decants_masculinos
  get "decants/femininos",  to: "produto#decants_femininos",  as: :decants_femininos
  get "decants/unissex", to: "produto#decants_unissex", as: :decants_unissex
  get "decants/nicho", to: "produto#decants_nicho", as: :decants_nicho
  get "produtos_todos", to: "produto#pag_todos_prod", as: :produtos_todos
  get "body-splash", to: "produto#body_splash", as: :body_splash
  get "hidratantes", to: "produto#hidratantes", as: :hidratantes
  get "busca", to: "produto#busca", as: :busca
  get "busca/sugestoes", to: "produto#sugestoes", as: :busca_sugestoes

  resources :produtos, controller: "produto", only: [:index, :show, :new, :create, :edit, :update, :destroy] # rubocop:disable Layout/SpaceInsideArrayLiteralBrackets
  get "produtos/:produto_id/avaliar", to: "avaliacoes#new", as: :avaliar_produto
  post "produtos/:produto_id/avaliacoes", to: "avaliacoes#create", as: :produto_avaliacoes
  patch "produtos/:produto_id/avaliacao", to: "avaliacoes#update", as: :produto_avaliacao
  resources :mensagens, only: [ :new, :create ]

  namespace :admin do
    get "avaliacoes", to: "avaliacoes#index", as: :avaliacoes
    patch "avaliacoes/:id", to: "avaliacoes#update", as: :avaliacao
    delete "avaliacoes/:id", to: "avaliacoes#destroy"
    resources :pedidos, only: [ :index, :show, :update ] do
      post :cancelar, on: :member
      post :confirmar_pagamento, on: :member
      post :notificar_whatsapp, on: :member
    end
    resources :mensagens, only: [ :index, :show, :destroy ]
    resources :videos_home, only: [ :create, :update, :destroy ]
    get "customizar", to: "customizar#index", as: :customizar
    patch "customizar/:id", to: "customizar#update", as: :atualizar_banner
    get "analisar", to: "analisar#index", as: :analisar
    get "configuracoes", to: "configuracoes#index", as: :configuracoes
    patch "configuracoes", to: "configuracoes#update"
  end

  resource :carrinho, only: [ :show ], controller: "carrinho" do
    post "adicionar", to: "itens_carrinho#create", as: :adicionar
    post "finalizar", to: "carrinho#finalizar", as: :finalizar
    delete "limpar", to: "carrinho#limpar", as: :limpar
  end

  resources :itens_carrinho, only: [ :update, :destroy ]
end
