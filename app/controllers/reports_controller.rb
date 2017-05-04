class ReportsController < ApplicationController

	def completed_immunizations
		@query = Observation.completed_immunizations
		@results = ActiveRecord::Base.connection.select_all( @query )
	end

	def individual_vaccination_counts_by_month_year
		@results = Observation.individual_vaccination_counts_by_month_year
	end

	def total_vaccination_counts
#		query = Observation.total_vaccination_counts
#		@sql = query.to_sql
#		@results = query.sort_by{|o| o.count }.reverse
		@results = Observation.total_vaccination_counts
	end

	def birth_weight_to_mom_age
		@results = Observation.birth_weight_to_mom_age
	end

	def birth_weight_group_to_prenatal_care
		@value = 'Prenatal Care'
		@results = Observation.birth_weight_group_to('prenatal')
		render action: 'birth_weight_group_to'
	end

	def birth_weight_group_to_alcohol_use
		@value = 'Alcohol Use'
		@results = Observation.birth_weight_group_to('alcohol')
		render action: 'birth_weight_group_to'
	end

	def birth_weight_group_to_drug_use
		@value = 'Drug Use'
		@results = Observation.birth_weight_group_to('drug_use')
		render action: 'birth_weight_group_to'
	end

	def birth_weight_group_to_otc_drug_use
		@value = 'OTC Drug Use'
		@results = Observation.birth_weight_group_to('du_otc')
		render action: 'birth_weight_group_to'
	end

	def birth_weight_group_to_prescription_drug_use
		@value = 'Prescription Drug Use'
		@results = Observation.birth_weight_group_to('du_prscr')
		render action: 'birth_weight_group_to'
	end

	def birth_weight_group_to_source_pay
		@value = 'Source Pay'
		@results = Observation.birth_weight_group_to('source_pay')
		render action: 'birth_weight_group_to'
	end

	def birth_weight_group_to_tobacco_use
		@value = 'Tobacco Use'
		@results = Observation.birth_weight_group_to('tobacco')
		render action: 'birth_weight_group_to'
	end

	def birth_weight_group_to_mom_age_group
		@value = 'Mom Age Group'
		@results = Observation.birth_weight_group_to('mom_age1')
		render action: 'birth_weight_group_to'
	end

	def birth_weight_group_to_mom_race
		@value = 'Mom Race'
		@results = Observation.birth_weight_group_to('mom_race1')
		render action: 'birth_weight_group_to'
	end

end
