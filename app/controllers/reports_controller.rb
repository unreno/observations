class ReportsController < ApplicationController

	def montly_birth_counts
	end

	def expected_immunizations
		@results = Observation.expected_immunizations
	end

	def individual_vaccination_counts_by_month_year
		@results = Observation.individual_vaccination_counts_by_month_year
	end

	def total_vaccination_counts
		@results = Observation.total_vaccination_counts
	end

end
