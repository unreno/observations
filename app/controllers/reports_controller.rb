class ReportsController < ApplicationController

	def montly_birth_counts
	end

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

end
