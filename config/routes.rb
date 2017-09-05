Rails.application.routes.draw do
  ActiveAdmin.routes(self)
  get '/landing', to: 'pages#landing', as: :landing
  root to: 'pages#home'
  devise_for :users,
    controllers: { omniauth_callbacks: 'users/omniauth_callbacks' }

  resources :conversations, only: [:index, :show, :create] do
    resources :messages, only: [:create]
  end
  resources :profiles, only: [:show, :index, :edit, :update] do
    resources :user_images, only: [:show, :destroy, :update]
    resources :matches, only: [:create]
    resources :dislikes, only: [:create]
  end
  post 'users/:id/match', to: 'matches#create', as: :match
  mount ActionCable.server => "/cable"
end

