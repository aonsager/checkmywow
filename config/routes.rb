require 'resque/server'
Rails.application.routes.draw do
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  root 'home#index'
  get 'logout' => 'home#logout'
  # get 'logs/:user' => 'logs#show'
  # get 'logs/:user/refresh' => 'logs#refresh'
  # get 'logs/import/:log_id' => 'logs#import', as: :import

  get 'about' => 'home#about'
  get 'announcement' => 'home#announcement'
  get 'changelog' => 'home#changelog'

  resources :players, only: [:show] do
    collection do
      get 'search'
    end
    resources :bosses, only: [] do
      get '/:difficulty' => 'bosses#show', as: :show
      get '/:difficulty/batch_parse' => 'bosses#batch_parse', as: :batch_parse
    end
  end

  resources :guilds, only: [:show] do
    get 'reload'
    collection do
      get 'search'
    end
  end

  resources :reports, only: [:show] do
    get 'status', :defaults => {:format => 'js'}
    get 'reload' => 'reports#reload', as: :reload, :defaults => {:format => 'js'}
    get 'batch/:player_id/' => 'reports#batch', as: :batch
    get 'load_fights/:player_id' => 'reports#load_fights', as: :load_fights, :defaults => { :format => 'js' }
    get 'fight_status/' => 'reports#fight_status', as: :fight_status, :defaults => { :format => 'js' }
    get '/:player_id' => 'reports#show_player', as: :player
    get '/:player_id/:fight_id' => 'fight_parses#show', as: :fight_parse
    get '/:player_id/:fight_id/changelog' => 'fight_parses#changelog', as: :changelog
    get '/:player_id/:fight_id/compare' => 'fight_parses#compare', as: :fp_compare
    get '/:fight_id/:player_id/load_hp_graph' => 'fight_parses#load_hp_graph', as: :load_hp_graph
    get '/:fight_id/:player_id/load_class_graph' => 'fight_parses#load_class_graph', as: :load_class_graph
    get '/:fight_id/:player_id/load_casts_table' => 'fight_parses#load_casts_table', as: :load_casts_table
    get '/:fight_id/:player_id/single_parse' => 'fight_parses#single_parse', as: :single_parse
    get '/:fight_id/:player_id/status' => 'fight_parses#status', as: :fp_status, :defaults => { :format => 'js' }
  end

  resources :zones, only: [:index] do
    collection do 
      get 'refresh'
    end
  end

  if Rails.env.development?
    mount Resque::Server.new, at: "/resque"
  end

  match '*path', via: :all, to: 'home#error_404'

end
