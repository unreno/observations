class ReportsController < ApplicationController
  def montly_birth_counts
  end

	def vaccination_count_by_year_month
		@results = Observation.vaccination_count_by_year_month
	end
end
