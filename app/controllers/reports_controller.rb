class ReportsController < ApplicationController

	def index
		$earliest_dob ||= ( Observation.where(concept: :dob).select('MIN(value) AS value')[0].value.try(:to_date) || Time.now )
		$latest_dob ||= ( Observation.where(concept: :dob).select('MAX(value) AS value')[0].value.try(:to_date) || Time.now )
		$earliest_imm ||= ( Observation.where(source_table: :immunizations).select('MIN(started_at) AS value')[0].value.try(:to_date) || Time.now )
		$latest_imm ||= ( Observation.where(source_table: :immunizations).select('MAX(started_at) AS value')[0].value.try(:to_date) || Time.now )
		$distinct_chirp_ids ||= Observation.count('DISTINCT chirp_id')
		$distinct_webiz_chirp_ids ||= Observation.where(source_schema: :webiz).count('DISTINCT chirp_id')
		$observation_count ||= Observation.count
		$attributes_counts ||= Observation.select(:concept).group(:concept).order(:concept).count
	end

	def enumerated_counts
		@results = Observation.enumerated_counts
	end

	def sex_birth_counts_by_quarter_year
		@results = Observation.sex_birth_counts_by_quarter_year
	end

	def sex_birth_counts_by_month_year
		@results = Observation.sex_birth_counts_by_month_year
	end

	def birth_counts_by_quarter_year
		@results = Observation.birth_counts_by_quarter_year
	end

	def birth_counts_by_quarter
		@results = Observation.birth_counts_by_quarter
	end

	def birth_counts_by_month_year
		@results = Observation.birth_counts_by_month_year
	end

	def birth_counts_by_month
		@results = Observation.birth_counts_by_month
	end

	def source_pay_birth_counts_by_month_year
		@results = Observation.source_pay_birth_counts_by_month_year
	end

	def parallel_coords
		@results = Observation.parallel_coords
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
