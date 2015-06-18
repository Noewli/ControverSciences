Rails.application.routes.draw do
  root             'static_pages#home'
  get 'how_to'    => 'static_pages#how_to'
  get 'how_to_edit'    => 'static_pages#how_to_edit'
  get 'faq'    => 'static_pages#faq'
  get 'terms'    => 'static_pages#terms'
  get 'about'   => 'static_pages#about'
  get 'contact' => 'static_pages#contact'
  get 'empty_references'    => 'static_pages#empty_references'
  get 'empty_summaries'   => 'static_pages#empty_summaries'
  get 'empty_comments' => 'static_pages#empty_comments'
  get 'newsletter' => 'static_pages#newsletter'
  get 'signup' => 'users#new'
  get    'login'    => 'sessions#new'
  delete 'logout'   => 'sessions#destroy'
  resources :users do
    collection do
      get 'checkemail'
    end
  end
  resources :user_details, only: [:create]
  resources :sessions, only: [:new, :create, :destroy]
  resources :account_activations, only: [:edit]
  resources :password_resets,     only: [:new, :create, :edit, :update]
  resources :timelines, only: [:new, :create, :index, :show, :edit, :update, :destroy]
  resources :references, only: [:new, :create, :show, :edit, :update, :destroy]
  get "/next" => 'references#next', as: 'next_reference'
  get "/previous" => 'references#previous', as: 'previous_reference'
  get "/from_timeline" => 'references#from_timeline', as: 'from_timeline'
  get "/from_reference" => 'references#from_reference', as: 'from_reference'
  resources :comments, only: [:show, :new, :create, :edit, :update, :destroy]
  resources :votes, only: [:new ,:create, :destroy]
  resources :ratings, only: [:create, :destroy]
  resources :binaries, only: [:create, :destroy]
  get 'assistant' => 'assistant#view'
  get 'assistant/users' => 'assistant#users'
  get 'assistant/index' => 'assistant#index'
  resources :pending_users, only: [:destroy]
  get 'assistant/timelines' => 'assistant#timelines'
  get 'assistant/fitness' => 'assistant#fitness'
  get 'assistant/selection' => 'assistant#selection'
  get 'notifications/index'
  get 'notifications/important'
  get 'notifications/delete_all'
  get 'notifications/delete_all_important'
  post 'notifications/delete'
  get 'notifications/timeline'
  get 'notifications/reference'
  get 'notifications/comment'
  get 'notifications/summary'
  get 'notifications/selection'
  get 'notifications/summary_selection'
  get 'notifications/selection_win'
  get 'notifications/summary_selection_win'
  get 'notifications/selection_loss'
  get 'notifications/summary_selection_loss'
  get 'notifications/suggestion'
  get 'notifications/suggestions'

  get 'my_items/items'
  get 'my_items/votes'

  resources :likes, only: [:create, :destroy, :index]
  resources :newsletters, only: [:create]

  resources :summaries, only: [:show, :index, :new, :create, :edit, :update, :destroy]
  resources :credits, only: [:new ,:create, :destroy]

  resources :frames, only: [:show, :index, :new, :create, :edit, :update, :destroy]
  resources :frame_credits, only: [:new ,:create, :destroy]
  resources :suggestions, only: [:index, :create, :show, :edit, :update, :destroy]
  resources :suggestion_children, only: [:create, :show, :edit, :update, :destroy]
  get "/fetch_children" => 'suggestion_children#from_suggestion', as: 'fetch_children'

  resources :suggestion_votes, only: [:create]
  resources :suggestion_child_votes, only: [:create]

  resources :issues, only: [:create]
  resources :figures, only: [:create]

  resources :typos, only: [:create, :new, :show, :destroy]
  get 'typos_accept' => 'typos#accept', as: 'typos_accept'

  resources :edges, only: [:index, :create]

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
