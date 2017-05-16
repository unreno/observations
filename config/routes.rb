Rails.application.routes.draw do

	resources :reports, only: :index do
		collection do
			get :completed_immunizations
			get :individual_vaccination_counts_by_month_year
			get :total_vaccination_counts
			get :birth_weight_to_mom_age
			get :birth_weight_to_tot_cigs
			get :birth_weight_group_percents_to
#			get :birth_weight_group_to_alcohol_use
#			get :birth_weight_group_to_drug_use
#			get :birth_weight_group_to_otc_drug_use
#			get :birth_weight_group_to_prescription_drug_use
#			get :birth_weight_group_to_prenatal_care
#			get :birth_weight_group_to_source_pay
#			get :birth_weight_group_to_tobacco_use
#			get :birth_weight_group_to_mom_age_group
#			get :birth_weight_group_to_mom_race
#			get :birth_weight_group_to_momrace_ethnchs
		end
	end

#	get 'birth_weight_group_to/:v(.:format)' => 'birth_weight_group_to#show'
	resource :birth_weight_group_to, only: :show


	# For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
#	resources :observations, only: :index
	resources :observations, only: :index, defaults: { format: :json }

	root :to => "reports#index"
#	root :to => "observations#index"

end
