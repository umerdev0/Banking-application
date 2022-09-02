# frozen_string_literal: true

Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :banks, only: %i[index show create update destroy]
      resources :accounts, only: %i[index show create update destroy]
      resources :transactions, only: %i[index show create update destroy] do
        member { put :mark_duplicate }
      end
    end
  end
end
