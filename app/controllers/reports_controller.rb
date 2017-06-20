class ReportsController < ApplicationController

	def parallel_coords
		@results = Observation.parallel_coord_test
	end

	def ave_birth_weight_to_zip
		@results = Observation.ave_birth_weight_to_zip
	end

	def birth_weight_group_to_percent_of
		@value = params[:v] || 'DEM:Zip'
		@query = Observation.birth_weight_group_percents_to( @value )
		@results = ActiveRecord::Base.connection.select_all( @query )
	end

	def completed_immunizations
		@query = Observation.completed_immunizations
		@results = ActiveRecord::Base.connection.select_all( @query )
	end

	def individual_vaccination_counts_by_month_year
		@results = Observation.individual_vaccination_counts_by_month_year
	end

	def total_vaccination_counts
		@results = Observation.total_vaccination_counts
	end

	def birth_weight_to_mom_age
		@results = Observation.birth_weight_to_mom_age
	end

	def birth_weight_to_tot_cigs
		@results = Observation.birth_weight_to_tot_cigs
	end

end
