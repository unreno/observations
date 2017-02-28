Rails.application.routes.draw do
#  get 'reports/montly_birth_counts'

	resources :reports, only: :index do
		collection do
			get :individual_vaccination_counts_by_month_year
			get :total_vaccination_counts
		end
	end

	# For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
	resources :observations, only: :index

	root :to => "reports#individual_vaccination_counts_by_month_year"
#	root :to => "observations#index"

end
