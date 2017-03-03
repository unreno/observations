class ReportsController < ApplicationController

	def montly_birth_counts
	end

	def completed_immunizations
		@results = ActiveRecord::Base.connection.select_all(Observation.completed_immunizations)
	end

	def individual_vaccination_counts_by_month_year
		@results = Observation.individual_vaccination_counts_by_month_year
	end

	def total_vaccination_counts
		@results = Observation.total_vaccination_counts
	end

end
