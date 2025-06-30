Rails.application.routes.draw do
  # Dashboard routes
  root "dashboard#index"
  get "dashboard", to: "dashboard#index"
  get "dashboard/souls", to: "dashboard#souls"
  get "dashboard/incarnations", to: "dashboard#incarnations", as: :incarnations_dashboard
  get "dashboard/soul/:id", to: "dashboard#soul", as: :soul_dashboard
  
  # Forge session routes
  resources :forge_sessions do
    member do
      patch :start
      patch :end
    end
  end

  namespace :api do
    namespace :v1 do
      resources :incarnations, only: [:create] do
        member do
          post :end
        end
      end
      
      resources :events, only: [] do
        collection do
          post :batch
        end
      end
      
      resources :souls, only: [:index, :show]
      
      resources :sessions, only: [] do
        member do
          post :heartbeat
        end
      end
    end
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
