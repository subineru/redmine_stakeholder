RedmineApp::Application.routes.draw do
  resources :projects do
    resources :stakeholders do
      collection do
        get :analytics
      end
      member do
        patch :inline_update
        get :history
      end
    end
  end
end
