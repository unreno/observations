class ReportsController < ApplicationController

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

end
