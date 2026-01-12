Rails.application.routes.draw do
  devise_for :users, controllers: { registrations: 'users/registrations' }
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  resources :organizations do
    collection do
      get :dashboard
    end
  end

  resources :users do
    member do
      get :dashboard
      patch :superadmin_menu
    end
  end

  resources :offers

  resources :calculations, only: %i[create] do
    member do
      patch :set_current
      post :copy
    end

    resources :calculation_rows, only: %i[new create edit update destroy] do
      resources :row_adjustments, only: %i[index create destroy]
    end
  end

  resources :clients do
    collection do
      get :search
    end
  end

  resources :product_categories

  resources :products, shallow: true do
    resources :variants, only: %i[ new create ]
    
    member do
      get :toggle_variants
    end
  end

  resources :variants, only: %i[ index show edit update destroy ] do
    collection do
      get :stock_index
      get :scanner
      get :search
    end

    member do
      get :toggle_items
    end
  end

  resources :items

  resources :stock_operations

  resources :stock_movements, only: %i[ index show ] do
    collection do
      get :receive
      post :create_receive
      get :issue
      post :create_issue
      get :adjust
      post :create_adjust

      post :set_items_to_issue
      post :set_items_to_receive
    end
  end

  resources :import_runs, only: %i[ index show new create ]

  authenticated :user do
    root to: 'users#dashboard', as: :authenticated_root
  end

  unauthenticated do
    root to: 'landing#index', as: :unauthenticated_root
  end

  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end
end
