namespace :app do
	desc "Create Parallel Coords csv"
	task :create_parallel_coords_csv => :environment do
		require 'csv'
		results = Observation.parallel_coords
#		puts results.to_sql
		columns = %w{ birth_weight_grams mother_age pre_preg_weight delivery_weight
			alcohol_use drug_use tobacco_use prenatal_care sex mother_weight_change
			facility_type source_pay prepreg_cig first_cig sec_cig last_cig drinks_per_week}

		#	puts columns.inspect
		puts columns.to_csv

		results.each do |r|
			puts columns.collect{|c|r[c]}.to_csv
		end
		
	end
end