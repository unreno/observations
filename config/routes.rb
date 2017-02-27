Rails.application.routes.draw do
#  get 'reports/montly_birth_counts'
	get 'reports/vaccination_count_by_year_month'

	# For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
	resources :observations, only: :index

	root :to => "observations#index"

end
