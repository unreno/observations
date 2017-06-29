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

	desc "Create TSV for Clustergrammer"
	task :create_clustergrammer_tsv => :environment do
		require 'csv'
		results = Observation.clustergrammer_matrix
#		puts results.to_sql
		columns = %w{ chirp_id birth_weight_grams mother_age pre_preg_weight delivery_weight
			alcohol_use drug_use tobacco_use prenatal_care sex mother_weight_change
			facility_type source_pay prepreg_cig first_cig sec_cig last_cig drinks_per_week}

		#	puts columns.inspect
		puts columns.to_csv({ col_sep: "\t" })

		results.each do |r|
#			puts columns.collect{|c|r[c]||'NaN'}.to_csv({ col_sep: "\t" })
			puts columns.collect{|c|r[c]||0}.to_csv({ col_sep: "\t" })
		end
		
#	rake app:create_clustergrammer_tsv > mult_view.tsv
#	python create_clustergrammer_json.py 
	end
end
