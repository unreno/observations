class Observation < ApplicationRecord
	#
	#	Can't alias initial table unless, start with arel_table and end with find_by_sql (or the like)
	#
	#	They REALLY don't want you to alias that first table.
	#	Its all behind the scenes so it really doesn't matter much.
	#
	def self.completed_immunizations
		o1=Observation.arel_table # same as o1=Arel::Table.new('observations'), can't alias
		o3=o1.alias('o3')
		o4=o1.alias('o4')

#	NEED TO ADD THE DOB/VAC date comparison. Looks done

#			.outer_join(o4).on(o1[:chirp_id].eq(o4[:chirp_id]))
#			.where(o4[:concept].eq('vaccination_desc'))
		inside_select = o1
			.join(o4).on(o1[:chirp_id].eq(o4[:chirp_id])
				.and(o4[:concept].eq('vaccination_desc')))
			.where(o1[:concept].eq('dob'))
			.where(o1[:value].matches('2015%'))
			.project(o1[:chirp_id])
			.project("CAST( observations.value AS DATE ) AS dob")
			.project(o4[:started_at])
			.project(o4[:value].as('vaccination'))
			.distinct		#	done to drop any duplicates

#			.project(o1[:value].as('dob'))
#			.group(o1[:chirp_id],o1[:value],o4[:started_at],o4[:value])

		#	Make this a field rather than a condition to try to make faster???
		#	Still take 47 seconds in sql server while mysql only takes 8???
		#	I don't understand it, but CASTing dob to a DATE makes this faster?
		#	I wouldn't have expected casting the field into another variable would affect the field?
		inside_select = if ActiveRecord::Base.connection_config[:adapter] == 'qlserver'
			inside_select.where(Arel.sql("[o4].[started_at] < DATEADD(month, 7, [observations].[value])"))
#			inside_select.project(Arel.sql("DATEADD(month, 7, [observations].[value]) AS dob7"))
		elsif ActiveRecord::Base.connection_config[:adapter] == 'mysql2'
			inside_select.where(Arel.sql("`o4`.`started_at` < DATE_ADD(`observations`.`value`,INTERVAL 7 MONTH)"))
#			inside_select.project(Arel.sql("DATE_ADD(`observations`.`value`,INTERVAL 7 MONTH) AS dob7"))
		else
			raise "I'm confused"
		end

		inside = Arel::Table.new('inside')
		#	SUM(CASE ... is not agnostic but seems to work on both MySQL/MariaDB and SQL Server!
		outside_select = Observation.from(inside_select.as('inside').to_sql)
			.group(inside[:chirp_id], inside[:dob])
			.select(inside[:chirp_id], inside[:dob])
			.project("SUM(CASE WHEN vaccination = 'DTAP' THEN 1 ELSE 0 END) AS dtap_count")
			.project("SUM(CASE WHEN vaccination = 'Hep B' THEN 1 ELSE 0 END) AS hepb_count")
			.project("SUM(CASE WHEN vaccination = 'HIB (2 dose)' THEN 1 ELSE 0 END) AS hib2_count")
			.project("SUM(CASE WHEN vaccination = 'HIB' THEN 1 ELSE 0 END) AS hib3_count")
			.project("SUM(CASE WHEN vaccination = 'PCV 13' THEN 1 ELSE 0 END) AS pcv_count")
			.project("SUM(CASE WHEN vaccination = 'IPV' THEN 1 ELSE 0 END) AS ipv_count")
			.project("SUM(CASE WHEN vaccination = 'Rotavirus (2 dose)' THEN 1 ELSE 0 END) AS r2_count")
			.project("SUM(CASE WHEN vaccination = 'Rotavirus (3 dose)' THEN 1 ELSE 0 END) AS r3_count")
			.as('outside')

		outside = Arel::Table.new('outside')	#	same name as in .as(...) above
		xyz = Observation.from(outside_select.to_sql)
			.select(Arel.star)
			.where(outside[:dtap_count].gteq(3))
			.where(outside[:ipv_count].gteq(2))
			.where(outside[:pcv_count].gteq(3))
			.where(outside[:hepb_count].gteq(2))
			.where(outside[:hib2_count].gteq(2).or(outside[:hib3_count].gteq(3)))
			.where(outside[:r2_count].gteq(2).or(outside[:r3_count].gteq(3)))

#	=> 2598!  Just like initial SQL Server query!
#	However, now sql server on linux is taking 47 seconds!!!
#	and mysql is taking only 9
#	Now sql server is faster with casting of dob as date
#	ActiveRecord::Base.connection.execute(sql);	#	only returns count on SQL Server?
#	ActiveRecord::Base.connection.select_rows(sql);	#	returns an array of arrays (no fields)
#	Neither are really any faster.
#		Observation.find_by_sql(xyz)
#	Use ActiveRecord::Base.connection.select_all(sql);	#	returns an array of arrays (no fields)
#> results.columns
#=> ["chirp_id", "dob", "dtap_count", "hepb_count", "hib2_count", "hib3_count", "pcv_count", "ipv_count", "r2_count", "r3_count"]
#> results.rows.length
#=> 2598
#	Access like an array of hashes
#> results[555]
#=> {"chirp_id"=>12312341234123, "dob"=>Sat, 00 Xxx 2015, "dtap_count"=>3, "hepb_count"=>3, "hib2_count"=>0, "hib3_count"=>3, "pcv_count"=>3, "ipv_count"=>3, "r2_count"=>0, "r3_count"=>3}
#	You don't even need to ".to_sql"
	end

	def self.total_vaccination_counts
		o1at = Observation.arel_table	#	don't think that I can alias the initial table
		o2at = Observation.arel_table.alias('o2')

		o1 = o1at
			.where(o1at[:concept].eq('dob'))
			.where(o1at[:value].matches('2015%'))
			.project("'Total Distinct CHIRP IDs' AS vaccination")
			.project( o1at[:chirp_id].count(:distinct).as('count') )

#			.outer_join( o2at ).on( o1at[:chirp_id].eq(o2at[:chirp_id]) )
#			.where(o2at[:concept].eq('vaccination_desc'))
		o2 = o1at
			.join( o2at ).on( o1at[:chirp_id].eq(o2at[:chirp_id])
				.and(o2at[:concept].eq('vaccination_desc')) )
			.where(o1at[:concept].eq('dob'))
			.where(o1at[:value].matches('2015%'))
			.project("'CHIRP IDs with WebIZ Match' AS vaccination")
			.project( o1at[:chirp_id].count(:distinct).as('count') )

#			.outer_join( o2at ).on( o1at[:chirp_id].eq(o2at[:chirp_id]) )
#			.where(o2at[:concept].eq('vaccination_desc'))
		o3 = o1at
			.join( o2at ).on( o1at[:chirp_id].eq(o2at[:chirp_id])
				.and(o2at[:concept].eq('vaccination_desc')) )
			.where(o1at[:concept].eq('dob'))
			.where(o1at[:value].matches('2015%'))
			.project(o2at[:value].as('vaccination'))
			.project(o2at[:chirp_id].count(:distinct).as('count') )
			.group(o2at[:value])

		#	Can only union 2 queries, so need to union 2, then union the result to another, etc.
#
#		union1 = o1.union(o2)
#		table1 = Observation.select("first_union.*").from(o1at.create_table_alias(union1,:first_union).to_sql)
#		union2 = table1.union(o3)
#		table2 = Observation.from(o1at.create_table_alias(union2,:observations).to_sql)

		Observation.from( o1at.create_table_alias(
				Observation.select("first_union.*").from(
					o1at.create_table_alias(
						o1.union(o2),:first_union).to_sql).union(o3),
				:observations).to_sql)
			.order(o1at[:count].desc())
	end

	def self.individual_vaccination_counts_by_month_year
		o1at = Observation.arel_table	#	don't think that I can alias the initial table
		o3at = Observation.arel_table.alias('o3')

		group_year_vac = Arel::Nodes::NamedFunction.new("YEAR", [o3at[:started_at]])
		group_month_vac = Arel::Nodes::NamedFunction.new("MONTH", [o3at[:started_at]])
		year_vac = Arel::Nodes::NamedFunction.new("YEAR", [o3at[:started_at]], "year")
		month_vac = Arel::Nodes::NamedFunction.new("MONTH", [o3at[:started_at]], "month")

#	This will include records without webiz records
#			.joins( outer(o3at, o1at[:chirp_id].eq(o3at[:chirp_id])
#				.and(o3at[:concept].eq('vaccination_desc'))) )
#
#			.joins( outer(o3at, o1at[:chirp_id].eq(o3at[:chirp_id])))
#			.where( o3at[:concept].eq('vaccination_desc') )
		results = Observation
			.joins( inner(o3at, o1at[:chirp_id].eq(o3at[:chirp_id])
				.and(o3at[:concept].eq('vaccination_desc'))) )
			.where( o1at[:concept].eq('dob') )
			.where( o1at[:value].matches('2015%') )
			.group( group_year_vac, group_month_vac )
			.order( group_year_vac, group_month_vac )
			.select( year_vac, month_vac )
			.select( o1at[:chirp_id].count.as('count') )

#			.select(o1at[:chirp_id].count.as('count'))
#	SAME AS ??
#			.select("COUNT(1) AS count")

#	DO NOT DO (syntactically correct, but statistically wrong)
#			.select(o1at[:chirp_id].count(:distinct).as('count'))
	end

	def self.birth_weight_to_mom_age
		o1at = Observation.arel_table	#	don't think that I can alias the initial table
		o2at = Observation.arel_table.alias('o2')

		weight = Arel::Nodes::NamedFunction.new("CAST", [o1at[:value].as("INT")], "weight")
		mom_age = Arel::Nodes::NamedFunction.new("CAST", [o2at[:value].as("INT")], "b2_mother_age")

		Observation
			.joins( outer(o2at, o1at[:chirp_id].eq(o2at[:chirp_id])
				.and(o2at[:concept].eq('b2_mother_age'))))
			.where( o1at[:concept].eq 'birth_weight_grams' )
			.where( o1at[:units].eq 'grams' )
			.where( o1at[:source_table].eq 'births' )
			.select( weight, mom_age.as('mom_age') )
	end

	def self.birth_weight_to_tot_cigs
		o1at = Observation.arel_table	#	don't think that I can alias the initial table
		o2at = Observation.arel_table.alias('o2')
		o3at = Observation.arel_table.alias('o3')
		o4at = Observation.arel_table.alias('o4')
		o5at = Observation.arel_table.alias('o5')

		weight = Arel::Nodes::NamedFunction.new("CAST", [o1at[:value].as("INT")], "weight")
		prepreg_cig = Arel::Nodes::NamedFunction.new("CAST", [o2at[:value].as("INT")], "b2_mother_cig_prev")
		first_cig = Arel::Nodes::NamedFunction.new("CAST", [o3at[:value].as("INT")], "b2_mother_cig_first_tri")
		sec_cig = Arel::Nodes::NamedFunction.new("CAST", [o4at[:value].as("INT")], "b2_mother_cig_second_tri")
		last_cig = Arel::Nodes::NamedFunction.new("CAST", [o5at[:value].as("INT")], "b2_mother_cig_last_tri")

#	Not quite there yet.
#		tot_cigs = Arel::Nodes::Addition.new(
#			Arel::Nodes::Addition.new(
#				Arel::Nodes::Addition.new(
#					Arel::Nodes::Multiplication.new(90,prepreg_cig),
#					Arel::Nodes::Multiplication.new(90,first_cig) ),
#					Arel::Nodes::Multiplication.new(90,sec_cig) ),
#					Arel::Nodes::Multiplication.new(90,last_cig) ).as('tot_cigs2')

		Observation
			.joins( outer(o2at, o1at[:chirp_id].eq(o2at[:chirp_id])
				.and( o2at[:concept].eq('b2_mother_cig_prev') ).and( o2at[:value].not_eq('99') )))
			.joins( outer(o3at, o1at[:chirp_id].eq(o3at[:chirp_id])
				.and( o3at[:concept].eq('b2_mother_cig_first_tri') ).and( o3at[:value].not_eq('99') )))
			.joins( outer(o4at, o1at[:chirp_id].eq(o4at[:chirp_id])
				.and( o4at[:concept].eq('b2_mother_cig_second_tri') ).and( o4at[:value].not_eq('99') )))
			.joins( outer(o5at, o1at[:chirp_id].eq(o5at[:chirp_id])
				.and( o5at[:concept].eq('b2_mother_cig_last_tri') ).and( o5at[:value].not_eq('99') )))
			.where( o1at[:concept].eq 'birth_weight_grams' )
			.where( o1at[:units].eq 'grams' )
			.where( o1at[:source_table].eq 'births' )
			.select( o1at[:chirp_id], weight, prepreg_cig, first_cig, sec_cig, last_cig,
				"( 90*CAST( o2.value AS INT ) + 90*CAST( o3.value AS INT ) + 90*CAST( o4.value AS INT ) + 90*CAST( o5.value AS INT ) ) AS tot_cigs" )	#, tot_cigs)

#	sadly no elegant arel way to add these columns found just yet
#	Could use Arel::Nodes::Addition.new(a,b) [only takes 2 so would have to do multiple times]

#			.select( o1at[:chirp_id], weight, prepreg_cig + first_cig )#, tot_cig )

	end

	def self.birth_weight_group_percents_to( field, as = nil )
		o1at = Observation.arel_table	#	don't think that I can alias the initial table
		o2at = o1at.alias('o2')

		grouping_table_name = 'grouping'

		grouping_sql = o1at
			.project( o1at[:value].as 'name' )
			.project( o1at[:value].count.as 'total' )
			.where( o1at[:concept].eq field )
			.where( o1at[:source_table].eq 'births' )
			.group( o1at[:value] )
			.as( grouping_table_name )

		#	same name as in .as(...) above (to be used when selecting or whereing)
		grouping = Arel::Table.new( grouping_table_name )

		#	select before join, project after join (same thing)
		outside_select = Observation.from(grouping_sql.to_sql)
			.select( o1at[:value].as 'value' )
			.select( o1at[:value].count.as 'count' )
			.select( o2at[:value].as 'birth_weight_group')
			.select( grouping[:total].as 'total' )
			.outer_join( o1at ).on( o1at[:value].eq( grouping[:name]))
			.where( o1at[:concept].eq field )
			.where( o1at[:source_table].eq 'births' )
			.outer_join( o2at ).on( o1at[:chirp_id].eq( o2at[:chirp_id]))
			.where( o2at[:concept].eq 'birth_weight_group')
			.group( o1at[:value], o2at[:value], grouping[:total] )
			.order( o1at[:value] )

#	SELECT `observations`.`value`,
#		COUNT(`observations`.`value`) AS count,
#		`o2`.`value` AS UNR:BirthWeightGroup,
#		`grouping`.`total` AS group_total
#	FROM (
#		SELECT `observations`.`value` AS name, COUNT(`observations`.`value`) AS total
#		FROM `observations`
#		WHERE `observations`.`concept` = 'DEM:Zip'
#		GROUP BY `observations`.`value`
#	) grouping
#	LEFT OUTER JOIN `observations` ON `observations`.`value` = `grouping`.`name`
#	LEFT OUTER JOIN `observations` `o2` ON `observations`.`chirp_id` = `o2`.`chirp_id`
#	WHERE `observations`.`concept` = 'DEM:Zip' AND `o2`.`concept` = 'UNR:BirthWeightGroup'
#	GROUP BY `observations`.`value`, `o2`.`value`

	end

	def self.birth_weight_group_to( field, as = nil )
		o1at = Observation.arel_table	#	don't think that I can alias the initial table
		o2at = Observation.arel_table.alias('o2')

		Observation
			.joins( outer(o2at, o1at[:chirp_id].eq(o2at[:chirp_id])
				.and( o2at[:concept].eq field ).and( o2at[:source_table].eq 'births' )))
			.where( o1at[:concept].eq 'birth_weight_group')
			.where( o1at[:source_table].eq 'births' )
			.group( o1at[:value], o2at[:value] )
			.select( o1at[:value].as('birth_weight_group'), o2at[:value] )
			.select( o1at[:chirp_id].count(:distinct).as('count') )
	end

	def self.birth_res_zip_code_to( field, as = nil )
		o1at = Observation.arel_table	#	don't think that I can alias the initial table
		o2at = Observation.arel_table.alias('o2')

		Observation
			.joins( outer(o2at, o1at[:chirp_id].eq(o2at[:chirp_id])
				.and( o2at[:concept].eq field ).and( o2at[:source_table].eq 'births' )))
			.where( o1at[:concept].eq 'birth_zip')
			.where( o1at[:source_table].eq 'births' )
			.group( o1at[:value], o2at[:value] )
			.select( o1at[:value].as('birth_res_zip_code'), o2at[:value] )
			.select( o1at[:chirp_id].count(:distinct).as('count') )
	end

	def self.birth_xy( x, y )
		o1at = Observation.arel_table	#	don't think that I can alias the initial table
		o2at = Observation.arel_table.alias('o2')

		Observation
			.joins( outer(o2at, o1at[:chirp_id].eq(o2at[:chirp_id])
				.and( o2at[:concept].eq y ).and( o2at[:source_table].eq 'births' )))
			.where( o1at[:concept].eq x )
			.where( o1at[:source_table].eq 'births' )
			.group( o1at[:value], o2at[:value] )
			.select( o1at[:value].as('x'), o2at[:value].as('y') )
			.select( o1at[:chirp_id].count(:distinct).as('count') )
	end

	def self.ave_birth_weight_to_zip
		o1at = Observation.arel_table	#	don't think that I can alias the initial table
		o2at = Observation.arel_table.alias('o2')

		weight = Arel::Nodes::NamedFunction.new("CAST", [o1at[:value].as("INT")])	#, 'weight')
		ave_weight = Arel::Nodes::NamedFunction.new("AVG", [weight])	#, 'avg_weight')

		Observation
			.joins( outer(o2at, o1at[:chirp_id].eq(o2at[:chirp_id])
				.and( o2at[:concept].eq 'birth_zip' ).and( o2at[:source_table].eq 'births' )))
			.where( o1at[:concept].eq 'birth_weight_grams' )
			.where( o1at[:source_table].eq 'births' )
			.where( o1at[:units].eq 'grams' )
			.group( o2at[:value] )
			.select( ave_weight.as('weight'), o2at[:value].as('zip') )
	end

	def self.birth_weight_birth_weight_group_check
		o1at = Observation.arel_table	#	don't think that I can alias the initial table
		o2at = Observation.arel_table.alias('o2')
		o4at = Observation.arel_table.alias('o4')

		Observation
			.joins( outer(o2at, o1at[:chirp_id].eq(o2at[:chirp_id])
				.and( o2at[:concept].eq 'birth_weight_group' ).and( o2at[:source_table].eq 'births' )))
			.joins( outer(o4at, o1at[:chirp_id].eq(o4at[:chirp_id])
				.and( o4at[:concept].eq('birth_zip') ).and( o4at[:source_table].eq 'births' )))
			.where( o1at[:concept].eq 'birth_weight_grams' )
			.where( o1at[:units].eq 'grams' )
			.where( o1at[:source_table].eq 'births' )
			.select( o1at[:value].as('weight'), o2at[:value].as('wgroup'), o4at[:value].as('zip') )
	end

#		def self.parallel_coord_test
#			o1at = Observation.arel_table	#	don't think that I can alias the initial table
#			o2at = Observation.arel_table.alias('o2')
#			o3at = Observation.arel_table.alias('o3')
#			o4at = Observation.arel_table.alias('o4')
#			o5at = Observation.arel_table.alias('o5')
#			o6at = Observation.arel_table.alias('o6')
#			o7at = Observation.arel_table.alias('o7')
#			o8at = Observation.arel_table.alias('o8')
#			o9at = Observation.arel_table.alias('o9')
#			o10at = Observation.arel_table.alias('o10')
#			o11at = Observation.arel_table.alias('o11')
#	
#			weight = Arel::Nodes::NamedFunction.new("CAST", [o1at[:value].as("INT")], "birth_weight_grams")
#			age = Arel::Nodes::NamedFunction.new("CAST", [o2at[:value].as("INT")], "mother_age")
#			alcohol_use = Arel::Nodes::NamedFunction.new("CAST", [o3at[:raw].as("INT")], "alcohol_use")
#			drug_use = Arel::Nodes::NamedFunction.new("CAST", [o4at[:raw].as("INT")], "drug_use")
#			tobacco_use = Arel::Nodes::NamedFunction.new("CAST", [o5at[:raw].as("INT")], "tobacco_use")
#			prenatal_care = Arel::Nodes::NamedFunction.new("CAST", [o6at[:raw].as("INT")], "prenatal_care")
#			pre_preg_weight = Arel::Nodes::NamedFunction.new("CAST", [o7at[:value].as("INT")], "pre_preg_weight")
#			delivery_weight = Arel::Nodes::NamedFunction.new("CAST", [o8at[:value].as("INT")], "delivery_weight")
#			mother_weight_change = Arel::Nodes::Subtraction.new(
#					Arel::Nodes::NamedFunction.new("CAST", [o8at[:value].as("INT")]),
#					Arel::Nodes::NamedFunction.new("CAST", [o7at[:value].as("INT")])
#				).as('mother_weight_change')
#			sex = Arel::Nodes::NamedFunction.new("CAST", [o9at[:raw].as("INT")], "sex")
#			facility_type = Arel::Nodes::NamedFunction.new("CAST", [o10at[:raw].as("INT")], "facility_type")
#			source_pay = Arel::Nodes::NamedFunction.new("CAST", [o11at[:raw].as("INT")], "source_pay")
#	
#			Observation
#				.joins( outer(o2at, o1at[:chirp_id].eq(o2at[:chirp_id])) )
#				.joins( outer(o3at, o1at[:chirp_id].eq(o3at[:chirp_id])) )
#				.joins( outer(o4at, o1at[:chirp_id].eq(o4at[:chirp_id])) )
#				.joins( outer(o5at, o1at[:chirp_id].eq(o5at[:chirp_id])) )
#				.joins( outer(o6at, o1at[:chirp_id].eq(o6at[:chirp_id])) )
#				.joins( outer(o7at, o1at[:chirp_id].eq(o7at[:chirp_id])) )
#				.joins( outer(o8at, o1at[:chirp_id].eq(o8at[:chirp_id])) )
#				.joins( outer(o9at, o1at[:chirp_id].eq(o9at[:chirp_id])) )
#				.joins( outer(o10at, o1at[:chirp_id].eq(o10at[:chirp_id])) )
#				.joins( outer(o11at, o1at[:chirp_id].eq(o11at[:chirp_id])) )
#				.where( o1at[:concept].eq 'birth_weight_grams' )
#				.where( o1at[:value].not_eq '8888' )
#				.where( o2at[:concept].eq('b2_mother_age') )
#				.where( o2at[:value].not_eq '99' )
#				.where( o3at[:concept].eq('m_alcohol_use') )
#				.where( o4at[:concept].eq('m_drug_use') )
#				.where( o5at[:concept].eq('b2_tobacco_use') )
#				.where( o6at[:concept].eq('b2_prenatal_yesno') )
#				.where( o7at[:concept].eq('b2_mother_pre_preg_wt') )
#				.where( o7at[:value].not_eq('999') )
#				.where( o8at[:concept].eq('b2_mother_wt_at_deliv') )
#				.where( o8at[:value].not_eq('999') )
#				.where( o9at[:concept].eq('sex') )
#				.where( o10at[:concept].eq('fac_type_code') )
#				.where( o11at[:concept].eq('b2_source_pay_code') )
#				.select( weight, age, alcohol_use, drug_use, tobacco_use, prenatal_care,
#					pre_preg_weight, delivery_weight, mother_weight_change, sex, facility_type, source_pay )
#	#			.limit(10)
#		end
#	
#		#	More than above
#		def self.parallel_coord_csv
#			o1at = Observation.arel_table	#	don't think that I can alias the initial table
#			o2at = Observation.arel_table.alias('o2')
#			o3at = Observation.arel_table.alias('o3')
#			o4at = Observation.arel_table.alias('o4')
#			o5at = Observation.arel_table.alias('o5')
#			o6at = Observation.arel_table.alias('o6')
#			o7at = Observation.arel_table.alias('o7')
#			o8at = Observation.arel_table.alias('o8')
#			o9at = Observation.arel_table.alias('o9')
#			o10at = Observation.arel_table.alias('o10')
#			o11at = Observation.arel_table.alias('o11')
#	
#			weight = Arel::Nodes::NamedFunction.new("CAST", [o1at[:value].as("INT")], "birth_weight_grams")
#			age = Arel::Nodes::NamedFunction.new("CAST", [o2at[:value].as("INT")], "mother_age")
#			alcohol_use = Arel::Nodes::NamedFunction.new("CAST", [o3at[:raw].as("INT")], "alcohol_use")
#			drug_use = Arel::Nodes::NamedFunction.new("CAST", [o4at[:raw].as("INT")], "drug_use")
#			tobacco_use = Arel::Nodes::NamedFunction.new("CAST", [o5at[:raw].as("INT")], "tobacco_use")
#			prenatal_care = Arel::Nodes::NamedFunction.new("CAST", [o6at[:raw].as("INT")], "prenatal_care")
#			pre_preg_weight = Arel::Nodes::NamedFunction.new("CAST", [o7at[:value].as("INT")], "pre_preg_weight")
#			delivery_weight = Arel::Nodes::NamedFunction.new("CAST", [o8at[:value].as("INT")], "delivery_weight")
#			mother_weight_change = Arel::Nodes::Subtraction.new(
#					Arel::Nodes::NamedFunction.new("CAST", [o8at[:value].as("INT")]),
#					Arel::Nodes::NamedFunction.new("CAST", [o7at[:value].as("INT")])
#				).as('mother_weight_change')
#			sex = Arel::Nodes::NamedFunction.new("CAST", [o9at[:raw].as("INT")], "sex")
#			facility_type = Arel::Nodes::NamedFunction.new("CAST", [o10at[:raw].as("INT")], "facility_type")
#			source_pay = Arel::Nodes::NamedFunction.new("CAST", [o11at[:raw].as("INT")], "source_pay")
#	
#			Observation
#				.joins( outer(o2at, o1at[:chirp_id].eq(o2at[:chirp_id])) )
#				.joins( outer(o3at, o1at[:chirp_id].eq(o3at[:chirp_id])) )
#				.joins( outer(o4at, o1at[:chirp_id].eq(o4at[:chirp_id])) )
#				.joins( outer(o5at, o1at[:chirp_id].eq(o5at[:chirp_id])) )
#				.joins( outer(o6at, o1at[:chirp_id].eq(o6at[:chirp_id])) )
#				.joins( outer(o7at, o1at[:chirp_id].eq(o7at[:chirp_id])) )
#				.joins( outer(o8at, o1at[:chirp_id].eq(o8at[:chirp_id])) )
#				.joins( outer(o9at, o1at[:chirp_id].eq(o9at[:chirp_id])) )
#				.joins( outer(o10at, o1at[:chirp_id].eq(o10at[:chirp_id])) )
#				.joins( outer(o11at, o1at[:chirp_id].eq(o11at[:chirp_id])) )
#				.where( o1at[:concept].eq 'birth_weight_grams' )
#				.where( o1at[:value].not_eq '8888' )
#				.where( o2at[:concept].eq('b2_mother_age') )
#				.where( o2at[:value].not_eq '99' )
#				.where( o3at[:concept].eq('m_alcohol_use') )
#				.where( o4at[:concept].eq('m_drug_use') )
#				.where( o5at[:concept].eq('b2_tobacco_use') )
#				.where( o6at[:concept].eq('b2_prenatal_yesno') )
#				.where( o7at[:concept].eq('b2_mother_pre_preg_wt') )
#				.where( o7at[:value].not_eq('999') )
#				.where( o8at[:concept].eq('b2_mother_wt_at_deliv') )
#				.where( o8at[:value].not_eq('999') )
#				.where( o9at[:concept].eq('sex') )
#				.where( o10at[:concept].eq('fac_type_code') )
#				.where( o11at[:concept].eq('b2_source_pay_code') )
#				.select( weight, age, alcohol_use, drug_use, tobacco_use, prenatal_care,
#					pre_preg_weight, delivery_weight, mother_weight_change, sex, facility_type, source_pay )
#	#			.order(o1at[:chirp_id])
#	#			.limit(100)
#		end

	#	Putting conditions in the join is MUCH FASTER and will then include empty values.
	def self.parallel_coords
		o1at = Observation.arel_table	#	don't think that I can alias the initial table
		o2at = Observation.arel_table.alias('o2')
		o3at = Observation.arel_table.alias('o3')
		o4at = Observation.arel_table.alias('o4')
		o5at = Observation.arel_table.alias('o5')
		o6at = Observation.arel_table.alias('o6')
		o7at = Observation.arel_table.alias('o7')
		o8at = Observation.arel_table.alias('o8')
		o9at = Observation.arel_table.alias('o9')
		o10at = Observation.arel_table.alias('o10')
		o11at = Observation.arel_table.alias('o11')
		o12at = Observation.arel_table.alias('o12')
		o13at = Observation.arel_table.alias('o13')
		o14at = Observation.arel_table.alias('o14')
		o15at = Observation.arel_table.alias('o15')
		o16at = Observation.arel_table.alias('o16')

		weight = Arel::Nodes::NamedFunction.new("CAST", [o1at[:value].as("INT")], "birth_weight_grams")
		age = Arel::Nodes::NamedFunction.new("CAST", [o2at[:value].as("INT")], "mother_age")
		alcohol_use = Arel::Nodes::NamedFunction.new("CAST", [o3at[:raw].as("INT")], "alcohol_use")
		drug_use = Arel::Nodes::NamedFunction.new("CAST", [o4at[:raw].as("INT")], "drug_use")
		tobacco_use = Arel::Nodes::NamedFunction.new("CAST", [o5at[:raw].as("INT")], "tobacco_use")
		prenatal_care = Arel::Nodes::NamedFunction.new("CAST", [o6at[:raw].as("INT")], "prenatal_care")
		pre_preg_weight = Arel::Nodes::NamedFunction.new("CAST", [o7at[:value].as("INT")], "pre_preg_weight")
		delivery_weight = Arel::Nodes::NamedFunction.new("CAST", [o8at[:value].as("INT")], "delivery_weight")
		mother_weight_change = Arel::Nodes::Subtraction.new(
				Arel::Nodes::NamedFunction.new("CAST", [o8at[:value].as("INT")]),
				Arel::Nodes::NamedFunction.new("CAST", [o7at[:value].as("INT")])
			).as('mother_weight_change')
		sex = Arel::Nodes::NamedFunction.new("CAST", [o9at[:raw].as("INT")], "sex")
		facility_type = Arel::Nodes::NamedFunction.new("CAST", [o10at[:raw].as("INT")], "facility_type")
		source_pay = Arel::Nodes::NamedFunction.new("CAST", [o11at[:raw].as("INT")], "source_pay")
		prepreg_cig = Arel::Nodes::NamedFunction.new("CAST", [o12at[:value].as("INT")], "prepreg_cig")
		first_cig = Arel::Nodes::NamedFunction.new("CAST", [o13at[:value].as("INT")], "first_cig")
		sec_cig = Arel::Nodes::NamedFunction.new("CAST", [o14at[:value].as("INT")], "sec_cig")
		last_cig = Arel::Nodes::NamedFunction.new("CAST", [o15at[:value].as("INT")], "last_cig")
		drinks_per_week = Arel::Nodes::NamedFunction.new("CAST", [o16at[:value].as("INT")], "drinks_per_week")

		Observation
			.joins( outer(o2at, o1at[:chirp_id].eq(o2at[:chirp_id])
				.and(o2at[:concept].eq('b2_mother_age')).and(o1at[:value].not_eq '8888')) )
			.joins( outer(o3at, o1at[:chirp_id].eq(o3at[:chirp_id])
				.and(o3at[:concept].eq('m_alcohol_use'))) )
			.joins( outer(o4at, o1at[:chirp_id].eq(o4at[:chirp_id])
				.and(o4at[:concept].eq('m_drug_use'))) )
			.joins( outer(o5at, o1at[:chirp_id].eq(o5at[:chirp_id])
				.and(o5at[:concept].eq('b2_tobacco_use'))) )
			.joins( outer(o6at, o1at[:chirp_id].eq(o6at[:chirp_id])
				.and(o6at[:concept].eq('b2_prenatal_yesno'))) )
			.joins( outer(o7at, o1at[:chirp_id].eq(o7at[:chirp_id])
				.and(o7at[:concept].eq('b2_mother_pre_preg_wt')).and(o7at[:value].not_eq('999'))) )
			.joins( outer(o8at, o1at[:chirp_id].eq(o8at[:chirp_id])
				.and(o8at[:concept].eq('b2_mother_wt_at_deliv')).and(o8at[:value].not_eq('999'))) )
			.joins( outer(o9at, o1at[:chirp_id].eq(o9at[:chirp_id])
				.and(o9at[:concept].eq('sex'))) )
			.joins( outer(o10at, o1at[:chirp_id].eq(o10at[:chirp_id])
				.and(o10at[:concept].eq('fac_type_code'))) )
			.joins( outer(o11at, o1at[:chirp_id].eq(o11at[:chirp_id])
				.and(o11at[:concept].eq('b2_source_pay_code') )) )
			.joins( outer(o12at, o1at[:chirp_id].eq(o12at[:chirp_id])
				.and(o12at[:concept].eq('b2_mother_cig_prev').and(o12at[:value].not_eq('99')) )) )
			.joins( outer(o13at, o1at[:chirp_id].eq(o13at[:chirp_id])
				.and(o13at[:concept].eq('b2_mother_cig_first_tri').and(o13at[:value].not_eq('99')) )) )
			.joins( outer(o14at, o1at[:chirp_id].eq(o14at[:chirp_id])
				.and(o14at[:concept].eq('b2_mother_cig_second_tri').and(o14at[:value].not_eq('99')) )) )
			.joins( outer(o15at, o1at[:chirp_id].eq(o15at[:chirp_id])
				.and(o15at[:concept].eq('b2_mother_cig_last_tri').and(o15at[:value].not_eq('99')) )) )
			.joins( outer(o16at, o1at[:chirp_id].eq(o16at[:chirp_id])
				.and(o16at[:concept].eq('m_alcohol_drink_week').and(o16at[:value].not_eq('99') ))) )
			.where( o1at[:concept].eq 'birth_weight_grams' )
			.where( o1at[:value].not_eq '8888' )
			.select( weight, age, alcohol_use, drug_use, tobacco_use, prenatal_care,
				pre_preg_weight, delivery_weight, mother_weight_change, sex, facility_type, source_pay,
				prepreg_cig, first_cig, sec_cig, last_cig, drinks_per_week )

#			.order(o1at[:chirp_id])
#			.limit(100)
	end

	
	def self.clustergrammer_matrix
		o1at = Observation.arel_table	#	don't think that I can alias the initial table
		o2at = Observation.arel_table.alias('o2')
		o3at = Observation.arel_table.alias('o3')
		o4at = Observation.arel_table.alias('o4')
		o5at = Observation.arel_table.alias('o5')
		o6at = Observation.arel_table.alias('o6')
		o7at = Observation.arel_table.alias('o7')
		o8at = Observation.arel_table.alias('o8')
		o9at = Observation.arel_table.alias('o9')
		o10at = Observation.arel_table.alias('o10')
		o11at = Observation.arel_table.alias('o11')
		o12at = Observation.arel_table.alias('o12')
		o13at = Observation.arel_table.alias('o13')
		o14at = Observation.arel_table.alias('o14')
		o15at = Observation.arel_table.alias('o15')
		o16at = Observation.arel_table.alias('o16')

		weight = Arel::Nodes::NamedFunction.new("CAST", [o1at[:value].as("INT")], "birth_weight_grams")
		age = Arel::Nodes::NamedFunction.new("CAST", [o2at[:value].as("INT")], "mother_age")
		alcohol_use = Arel::Nodes::NamedFunction.new("CAST", [o3at[:raw].as("INT")], "alcohol_use")
		drug_use = Arel::Nodes::NamedFunction.new("CAST", [o4at[:raw].as("INT")], "drug_use")
		tobacco_use = Arel::Nodes::NamedFunction.new("CAST", [o5at[:raw].as("INT")], "tobacco_use")
		prenatal_care = Arel::Nodes::NamedFunction.new("CAST", [o6at[:raw].as("INT")], "prenatal_care")
		pre_preg_weight = Arel::Nodes::NamedFunction.new("CAST", [o7at[:value].as("INT")], "pre_preg_weight")
		delivery_weight = Arel::Nodes::NamedFunction.new("CAST", [o8at[:value].as("INT")], "delivery_weight")
		mother_weight_change = Arel::Nodes::Subtraction.new(
				Arel::Nodes::NamedFunction.new("CAST", [o8at[:value].as("INT")]),
				Arel::Nodes::NamedFunction.new("CAST", [o7at[:value].as("INT")])
			).as('mother_weight_change')
		sex = Arel::Nodes::NamedFunction.new("CAST", [o9at[:raw].as("INT")], "sex")
		facility_type = Arel::Nodes::NamedFunction.new("CAST", [o10at[:raw].as("INT")], "facility_type")
		source_pay = Arel::Nodes::NamedFunction.new("CAST", [o11at[:raw].as("INT")], "source_pay")
		prepreg_cig = Arel::Nodes::NamedFunction.new("CAST", [o12at[:value].as("INT")], "prepreg_cig")
		first_cig = Arel::Nodes::NamedFunction.new("CAST", [o13at[:value].as("INT")], "first_cig")
		sec_cig = Arel::Nodes::NamedFunction.new("CAST", [o14at[:value].as("INT")], "sec_cig")
		last_cig = Arel::Nodes::NamedFunction.new("CAST", [o15at[:value].as("INT")], "last_cig")
		drinks_per_week = Arel::Nodes::NamedFunction.new("CAST", [o16at[:value].as("INT")], "drinks_per_week")

		Observation
			.joins( outer(o2at, o1at[:chirp_id].eq(o2at[:chirp_id])
				.and(o2at[:concept].eq('b2_mother_age')).and(o1at[:value].not_eq '8888')) )
			.joins( outer(o3at, o1at[:chirp_id].eq(o3at[:chirp_id])
				.and(o3at[:concept].eq('m_alcohol_use'))) )
			.joins( outer(o4at, o1at[:chirp_id].eq(o4at[:chirp_id])
				.and(o4at[:concept].eq('m_drug_use'))) )
			.joins( outer(o5at, o1at[:chirp_id].eq(o5at[:chirp_id])
				.and(o5at[:concept].eq('b2_tobacco_use'))) )
			.joins( outer(o6at, o1at[:chirp_id].eq(o6at[:chirp_id])
				.and(o6at[:concept].eq('b2_prenatal_yesno'))) )
			.joins( outer(o7at, o1at[:chirp_id].eq(o7at[:chirp_id])
				.and(o7at[:concept].eq('b2_mother_pre_preg_wt')).and(o7at[:value].not_eq('999'))) )
			.joins( outer(o8at, o1at[:chirp_id].eq(o8at[:chirp_id])
				.and(o8at[:concept].eq('b2_mother_wt_at_deliv')).and(o8at[:value].not_eq('999'))) )
			.joins( outer(o9at, o1at[:chirp_id].eq(o9at[:chirp_id])
				.and(o9at[:concept].eq('sex'))) )
			.joins( outer(o10at, o1at[:chirp_id].eq(o10at[:chirp_id])
				.and(o10at[:concept].eq('fac_type_code'))) )
			.joins( outer(o11at, o1at[:chirp_id].eq(o11at[:chirp_id])
				.and(o11at[:concept].eq('b2_source_pay_code') )) )
			.joins( outer(o12at, o1at[:chirp_id].eq(o12at[:chirp_id])
				.and(o12at[:concept].eq('b2_mother_cig_prev').and(o12at[:value].not_eq('99')) )) )
			.joins( outer(o13at, o1at[:chirp_id].eq(o13at[:chirp_id])
				.and(o13at[:concept].eq('b2_mother_cig_first_tri').and(o13at[:value].not_eq('99')) )) )
			.joins( outer(o14at, o1at[:chirp_id].eq(o14at[:chirp_id])
				.and(o14at[:concept].eq('b2_mother_cig_second_tri').and(o14at[:value].not_eq('99')) )) )
			.joins( outer(o15at, o1at[:chirp_id].eq(o15at[:chirp_id])
				.and(o15at[:concept].eq('b2_mother_cig_last_tri').and(o15at[:value].not_eq('99')) )) )
			.joins( outer(o16at, o1at[:chirp_id].eq(o16at[:chirp_id])
				.and(o16at[:concept].eq('m_alcohol_drink_week').and(o16at[:value].not_eq('99') ))) )
			.where( o1at[:concept].eq 'birth_weight_grams' )
			.where( o1at[:value].not_eq '8888' )
			.select( o1at[:chirp_id], weight, age, alcohol_use, drug_use, tobacco_use, prenatal_care,
				pre_preg_weight, delivery_weight, mother_weight_change, sex, facility_type, source_pay,
				prepreg_cig, first_cig, sec_cig, last_cig, drinks_per_week )
			.order(o1at[:chirp_id])
#			.limit(100)
	end

	def self.source_pay_birth_counts_by_month_year
		o1at = Observation.arel_table
		o2at = Observation.arel_table.alias('o2')

		birth_month = Arel::Nodes::NamedFunction.new("MONTH", [o1at[:value]], 'birth_month')
		birth_year = Arel::Nodes::NamedFunction.new("YEAR", [o1at[:value]], 'birth_year')
		group_birth_month = Arel::Nodes::NamedFunction.new("MONTH", [o1at[:value]])
		group_birth_year = Arel::Nodes::NamedFunction.new("YEAR", [o1at[:value]])

		Observation
			.joins( outer(o2at, o1at[:chirp_id].eq(o2at[:chirp_id])
				.and( o2at[:concept].eq 'b2_source_pay_code' ) ))
			.where( o1at[:concept].eq 'dob' )
			.group( group_birth_month, group_birth_year, o2at[:value] )
			.select( birth_month, birth_year, o2at[:value].as('source_pay') )
			.select("COUNT(1) AS count")
			.order( group_birth_year, group_birth_month, o2at[:value] )

#	this, for some reason, gets passed on to the group call as well.
#			.select( birth_month.as('birth_month'), birth_year.as('birth_year'), o2at[:value].as('sex') )
#	need an alias so can get them so need to create 2 named functions for each.
	end

	def self.birth_counts_by_quarter
		o1at = Observation.arel_table

		Observation
			.where( o1at[:concept].eq 'birth_quarter' )
			.group( o1at[:value] )
			.select( o1at[:value].as('birth_quarter') )
			.select("COUNT(1) AS count")
			.order( o1at[:value] )
	end

	def self.birth_counts_by_quarter_year
		o1at = Observation.arel_table
		o3at = Observation.arel_table.alias('o3')

		birth_year = Arel::Nodes::NamedFunction.new("YEAR", [o1at[:value]], 'birth_year')
		group_birth_year = Arel::Nodes::NamedFunction.new("YEAR", [o1at[:value]])
#		birth_quarter = Arel::Nodes::NamedFunction.new("DATEPART", ["q",o1at[:value]],'birth_quarter')
#		group_birth_quarter = Arel::Nodes::NamedFunction.new("DATEPART", ["q",o1at[:value]])

		Observation
			.joins( outer(o3at, o1at[:chirp_id].eq(o3at[:chirp_id])
				.and(o3at[:concept].eq('birth_quarter'))) )
			.where( o1at[:concept].eq 'dob' )
			.group( o3at[:value], group_birth_year )
			.select( o3at[:value].as('birth_quarter'), birth_year )
			.select("COUNT(1) AS count")
			.order( group_birth_year, o3at[:value] )
#		Observation
#			.where( o1at[:concept].eq 'dob' )
#			.group( "DATEPART(Q,`observations`.`value`)", group_birth_year )
#			.select( "DATEPART(Q,`observations`.`value`) AS birth_quarter", birth_year )
#			.select("COUNT(1) AS count")
#			.order( group_birth_year, "DATEPART(Q,`observations`.`value`)" )
	end

	def self.birth_counts_by_month
		o1at = Observation.arel_table

		birth_month = Arel::Nodes::NamedFunction.new("MONTH", [o1at[:value]], 'birth_month')
		group_birth_month = Arel::Nodes::NamedFunction.new("MONTH", [o1at[:value]])

		Observation
			.where( o1at[:concept].eq 'dob' )
			.group( group_birth_month )
			.select( birth_month )
			.select("COUNT(1) AS count")
			.order( group_birth_month )
	end

	def self.birth_counts_by_month_year
		o1at = Observation.arel_table

		birth_month = Arel::Nodes::NamedFunction.new("MONTH", [o1at[:value]], 'birth_month')
		birth_year = Arel::Nodes::NamedFunction.new("YEAR", [o1at[:value]], 'birth_year')
		group_birth_month = Arel::Nodes::NamedFunction.new("MONTH", [o1at[:value]])
		group_birth_year = Arel::Nodes::NamedFunction.new("YEAR", [o1at[:value]])

		Observation
			.where( o1at[:concept].eq 'dob' )
			.group( group_birth_month, group_birth_year )
			.select( birth_month, birth_year )
			.select("COUNT(1) AS count")
			.order( group_birth_year, group_birth_month )
	end

	def self.sex_birth_counts_by_month_year
		o1at = Observation.arel_table
		o2at = Observation.arel_table.alias('o2')

		birth_month = Arel::Nodes::NamedFunction.new("MONTH", [o1at[:value]], 'birth_month')
		birth_year = Arel::Nodes::NamedFunction.new("YEAR", [o1at[:value]], 'birth_year')
		group_birth_month = Arel::Nodes::NamedFunction.new("MONTH", [o1at[:value]])
		group_birth_year = Arel::Nodes::NamedFunction.new("YEAR", [o1at[:value]])

		Observation
			.joins( outer(o2at, o1at[:chirp_id].eq(o2at[:chirp_id])
				.and( o2at[:concept].eq 'sex' ) ))
			.where( o1at[:concept].eq 'dob' )
			.group( group_birth_month, group_birth_year, o2at[:value] )
			.select( birth_month, birth_year, o2at[:value].as('sex') )
			.select("COUNT(1) AS count")
			.order( group_birth_year, group_birth_month, o2at[:value] )

#	this, for some reason, gets passed on to the group call as well.
#			.select( birth_month.as('birth_month'), birth_year.as('birth_year'), o2at[:value].as('sex') )
#	need an alias so can get them so need to create 2 named functions for each.
	end

	def self.sex_birth_counts_by_quarter_year
		o1at = Observation.arel_table
		o2at = Observation.arel_table.alias('o2')
		o3at = Observation.arel_table.alias('o3')

		birth_year = Arel::Nodes::NamedFunction.new("YEAR", [o1at[:value]], 'birth_year')
		group_birth_year = Arel::Nodes::NamedFunction.new("YEAR", [o1at[:value]])

		Observation
			.joins( outer(o2at, o1at[:chirp_id].eq(o2at[:chirp_id])
				.and(o2at[:concept].eq('sex')) ))
			.joins( outer(o3at, o1at[:chirp_id].eq(o3at[:chirp_id])
				.and(o3at[:concept].eq('birth_quarter'))) )
			.where( o1at[:concept].eq 'dob' )
			.group( o3at[:value], group_birth_year, o2at[:value] )
			.select( o3at[:value].as('birth_quarter'), birth_year, o2at[:value].as('sex') )
			.select("COUNT(1) AS count")
			.order( group_birth_year, o3at[:value], o2at[:value] )
	end

	def self.enumerated_counts
		o1at = Observation.arel_table

		Observation
			.where( o1at[:concept].in( %w{
				apgar_10
				apgar_5
				attendant_title_code
				b2_birpresent_code
				b2_birroute_code
				b2_born_alive
				b2_father_age
				b2_father_cuban
				b2_father_ed
				b2_father_ethnic
				b2_father_ethnic_other
				b2_father_ethnic_yesno
				b2_father_mexican
				b2_father_pr
				b2_father_race_am_indian
				b2_father_race_am_ind_lit
				b2_father_race_asian_ind
				b2_father_race_asian_lit
				b2_father_race_asian_oth
				b2_father_race_black
				b2_father_race_chinese
				b2_father_race_filipino
				b2_father_race_guam
				b2_father_race_hawaiian
				b2_father_race_japanese
				b2_father_race_korean
				b2_father_race_other
				b2_father_race_other_lit
				b2_father_race_pac
				b2_father_race_pac_lit
				b2_father_race_refused
				b2_father_race_samoan
				b2_father_race_unknown
				b2_father_race_vietnamese
				b2_father_race_white
				b2_fa_bridged_race
				b2_frace16e
				b2_frace18e
				b2_frace1e
				b2_frace20e
				b2_frace22e
				b2_frace2e
				b2_frace3e
				b2_frace4e
				b2_frace5e
				b2_frace6e
				b2_hosp_paternity_complete
				b2_infant_living
				b2_mother_age
				b2_mother_cig_first_pack
				b2_mother_cig_first_tri
				b2_mother_cig_last_pack
				b2_mother_cig_last_tri
				b2_mother_cig_or_pack
				b2_mother_cig_prev
				b2_mother_cig_prev_pack
				b2_mother_cig_second_pack
				b2_mother_cig_second_tri
				b2_mother_cuban
				b2_mother_ed
				b2_mother_ethnic
				b2_mother_ethnic_other
				b2_mother_ethnic_yesno
				b2_mother_ever_married
				b2_mother_mexican
				b2_mother_pr
				b2_mother_race_am_indian
				b2_mother_race_am_ind_lit
				b2_mother_race_asian_ind
				b2_mother_race_asian_lit
				b2_mother_race_asian_oth
				b2_mother_race_black
				b2_mother_race_chinese
				b2_mother_race_filipino
				b2_mother_race_guam
				b2_mother_race_hawaiian
				b2_mother_race_japanese
				b2_mother_race_korean
				b2_mother_race_other
				b2_mother_race_other_lit
				b2_mother_race_pac_lit
				b2_mother_race_pac_other
				b2_mother_race_refused
				b2_mother_race_samoan
				b2_mother_race_unknown
				b2_mother_race_vietnamese
				b2_mother_race_white
				b2_mother_wic_yesno
				b2_mo_bridged_race
				b2_mrace16e
				b2_mrace18e
				b2_mrace1e
				b2_mrace20e
				b2_mrace22e
				b2_mrace2e
				b2_mrace3e
				b2_mrace4e
				b2_mrace5e
				b2_mrace6e
				b2_nchs_fa_ethnic_cd
				b2_nchs_fa_ethnic_lit_cd
				b2_nchs_mo_ethnic_cd
				b2_nchs_mo_ethnic_lit_cd
				b2_prenatal_yesno
				b2_prenat_tot_visits
				b2_source_pay_code
				b2_tobacco_use
				b2_trans_mother
				birth_order
				birth_weight_group
				birth_zip
				certifiertitleid
				death_matched
				fac_city_nv_old
				fac_cnty_nv_old
				fac_nv_code
				fac_st_nv_old
				fac_type_code
				father_birth_country_fips
				father_industry_cd
				father_is_husband
				father_occupation_cd
				father_sign_pat_affidavit
				fbir_country_country_code_nv
				fbir_state_fips_alpha_cd
				fbir_state_state_code_nv
				gestation_weeks
				isactive
				live_births_dead
				live_births_living
				live_births_total
				mbir_country_country_code_nv
				mbir_state_state_code_nv
				mother_age_group
				mother_birth_country_fips
				mother_birth_state
				mother_industry_cd
				mother_married
				mother_occupation_cd
				mother_res_city_fips
				mother_res_city_nv_old
				mother_res_cnty_fips
				mother_res_cnty_nv_old
				mother_res_country_fips
				mother_res_incity
				mother_res_state
				mother_res_zip
				mres_state_state_code_nv
				m_ac_anemia
				m_ac_antibiotic_sepsis
				m_ac_birth_injury
				m_ac_fas
				m_ac_hyaline
				m_ac_meconium_as
				m_ac_nicu
				m_ac_none
				m_ac_other
				m_ac_other_lit
				m_ac_seizures
				m_ac_surfactant
				m_ac_vent_less_30
				m_ac_vent_more_30
				m_alcohol_drink_week
				m_alcohol_use
				m_anom_anencep
				m_anom_cdit
				m_anom_chrom_lit
				m_anom_chrom_other
				m_anom_circ
				m_anom_circ_lit
				m_anom_cleft_lip
				m_anom_cleft_palate
				m_anom_club_foot
				m_anom_diaph_hernia
				m_anom_downs_code
				m_anom_gastro
				m_anom_gastroschisis
				m_anom_gastro_lit
				m_anom_heart
				m_anom_heart_malform
				m_anom_hypospadias
				m_anom_limb_reduct
				m_anom_malf_genitalia
				m_anom_micro
				m_anom_muscle
				m_anom_muscle_lit
				m_anom_nervous
				m_anom_nervous_lit
				m_anom_none
				m_anom_omphal
				m_anom_other
				m_anom_other_lit
				m_anom_polydact
				m_anom_rectal
				m_anom_renal
				m_anom_spina
				m_anom_tracheo
				m_anom_urogenital
				m_anom_urogenital_lit
				m_breastfeeding
				m_cld_abr_placenta
				m_cld_anesthetic
				m_cld_antibiotic
				m_cld_augment
				m_cld_bleeding
				m_cld_cephalopelvic
				m_cld_chorioamnio
				m_cld_cord_prolapse
				m_cld_dysfunctional
				m_cld_epidural
				m_cld_febrile
				m_cld_fetal_intolerance
				m_cld_induction
				m_cld_meconium
				m_cld_none
				m_cld_non_vertex
				m_cld_other
				m_cld_other_lit
				m_cld_placenta_previa
				m_cld_seizures
				m_cld_steroid
				m_drug_otc
				m_drug_other
				m_drug_other_lit
				m_drug_prescription
				m_drug_use
				m_inf_chlamydia
				m_inf_cmv
				m_inf_genital_herpes
				m_inf_gonorrhea
				m_inf_hepatitis_b
				m_inf_hepatitis_c
				m_inf_hiv_aids
				m_inf_hpv
				m_inf_none
				m_inf_other
				m_inf_other_lit
				m_inf_rubella
				m_inf_syphilis
				m_inf_toxoplasmosis
				m_inf_tuberculosis
				m_md_ces_labor_attempt
				m_md_forceps_attempt
				m_md_vacuum_attempt
				m_mm_hysterectomy
				m_mm_icu
				m_mm_none
				m_mm_or_proc
				m_mm_perineal_lacerat
				m_mm_ruptured_uterus
				m_mm_transfusion
				m_mm_unknown
				m_mr_anemia
				m_mr_assist_rep_tech
				m_mr_cardiac
				m_mr_diab
				m_mr_diab_gest
				m_mr_eclampsia
				m_mr_hemoglobinopathy
				m_mr_hydraminos_olig
				m_mr_hypert_all
				m_mr_hypert_chronic
				m_mr_hypert_preg
				m_mr_incompent_cervix
				m_mr_infert_drugs
				m_mr_lung_disease
				m_mr_none
				m_mr_other
				m_mr_other_lit
				m_mr_preg_from_treatment
				m_mr_prev_4000_plus
				m_mr_prev_cesarean_yesno
				m_mr_prev_ces_numb
				m_mr_prev_poor_outcome
				m_mr_prev_preterm
				m_mr_renal_disease
				m_mr_rh_sensit
				m_mr_uterine_bleeding
				m_ob_amnio
				m_ob_cephalic_failed
				m_ob_cephalic_success
				m_ob_cerclage
				m_ob_fetal_monitor
				m_ob_none
				m_ob_other
				m_ob_other_lit
				m_ob_tocolysis
				m_ob_ultrasound
				m_ol_none
				m_ol_precip_labor
				m_ol_premature_rom
				m_ol_prolong_labor
				plurality
				sex
				ssn_requested
				term_number
				trans_infant
			} ) )
			.group( o1at[:concept], o1at[:value] ).count
			.inject({}){|h,v| h[v[0][0]]||={};h[v[0][0]][v[0][1]] = v[1];h }

#irb(main):016:0> o.select{|k,v|k[0]=="m_ol_prolong_labor"}
#=> {["m_ol_prolong_labor", "No"]=>37128, ["m_ol_prolong_labor", "Yes"]=>854}

#o.inject({}){|h,v| h[v[0][0]]||={};h[v[0][0]][v[0][1]] = v[1];h }["m_ol_prolong_labor"]
#=> {"No"=>37128, "Yes"=>854}

	end

end
