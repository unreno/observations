Rails.application.routes.draw do

	resources :reports, only: :index do
		collection do
			get :completed_immunizations
			get :individual_vaccination_counts_by_month_year
			get :total_vaccination_counts
			get :montly_birth_counts
		end
	end

	# For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
#	resources :observations, only: :index

	root :to => "reports#index"
#	root :to => "observations#index"

end
