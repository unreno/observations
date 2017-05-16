class Observation < ApplicationRecord
	#
	#	Can't alias initial table unless, start with arel_table and end with find_by_sql (or the like)
	#
	#	They REALLY don't want you to alias that first table.
	#	Its all behind the scenes so it really doesn't matter much.
	#
	def self.completed_immunizations
		o1=Observation.arel_table # same as o1=Arel::Table.new('observations'), can't alias
		o2=o1.alias('o2')
		o3=o1.alias('o3')
		o4=o1.alias('o4')

#	NEED TO ADD THE DOB/VAC date comparison. Looks done

		inside_select = o1.outer_join(o2).on(o1[:chirp_id].eq(o2[:chirp_id]))
			.outer_join(o3).on(o1[:chirp_id].eq(o3[:chirp_id]))
			.outer_join(o4).on(o1[:chirp_id].eq(o4[:chirp_id]))
			.where(o1[:concept].eq('DEM:DOB'))
			.where(o1[:value].matches('2015%'))
			.where(o2[:concept].eq('birth_co'))
			.where(o2[:value].eq('Washoe'))
			.where(o3[:concept].eq('mom_rco'))
			.where(o3[:value].eq('Washoe'))
			.where(o4[:concept].eq('vaccination_desc'))
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
		inside_select = if ActiveRecord::Base.connection_config[:adapter] == 'sqlserver'
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
			.where(o1at[:concept].eq('DEM:DOB'))
			.where(o1at[:value].matches('2015%'))
			.project("'Total Distinct CHIRP IDs' AS vaccination")
			.project( o1at[:chirp_id].count(:distinct).as('count') )

		o2 = o1at
			.outer_join( o2at ).on( o1at[:chirp_id].eq(o2at[:chirp_id]) )
			.where(o1at[:concept].eq('DEM:DOB'))
			.where(o1at[:value].matches('2015%'))
			.where(o2at[:concept].eq('vaccination_desc'))
			.project("'CHIRP IDs with WebIZ Match' AS vaccination")
			.project( o1at[:chirp_id].count(:distinct).as('count') )

		o3 = o1at
			.outer_join( o2at ).on( o1at[:chirp_id].eq(o2at[:chirp_id]) )
			.where(o1at[:concept].eq('DEM:DOB'))
			.where(o1at[:value].matches('2015%'))
			.where(o2at[:concept].eq('vaccination_desc'))
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
		o2at = Observation.arel_table.alias('o2')
		o3at = Observation.arel_table.alias('o3')

		group_year_vac = Arel::Nodes::NamedFunction.new("YEAR", [o3at[:started_at]])
		group_month_vac = Arel::Nodes::NamedFunction.new("MONTH", [o3at[:started_at]])
		year_vac = Arel::Nodes::NamedFunction.new("YEAR", [o3at[:started_at]], "year")
		month_vac = Arel::Nodes::NamedFunction.new("MONTH", [o3at[:started_at]], "month")

		results = Observation
			.joins( outer(o2at, o1at[:chirp_id].eq(o2at[:chirp_id])) )
			.joins( outer(o3at, o1at[:chirp_id].eq(o3at[:chirp_id])) )
			.where( o1at[:concept].eq('DEM:DOB') )
			.where( o1at[:value].matches('2015%') )
			.where( o2at[:concept].eq('birth_co') )
			.where( o2at[:value].eq('Washoe') )
			.where( o3at[:concept].eq('vaccination_desc') )
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
		o3at = Observation.arel_table.alias('o3')

		weight = Arel::Nodes::NamedFunction.new("CAST", [o1at[:value].as("INT")], "weight")
		mom_age = Arel::Nodes::NamedFunction.new("CAST", [o2at[:value].as("INT")], "mom_age")

		Observation
			.joins( outer(o2at, o1at[:chirp_id].eq(o2at[:chirp_id])) )
			.joins( outer(o3at, o1at[:chirp_id].eq(o3at[:chirp_id])) )
			.where( o1at[:concept].eq 'DEM:Weight' )
			.where( o1at[:units].eq 'grams' )
			.where( o1at[:source_table].eq 'births' )
			.where( o2at[:concept].eq 'mom_age' )
			.where( o2at[:source_table].eq 'births' )
			.where( o3at[:concept].eq('birth_co') )
			.where( o3at[:value].eq('Washoe') )
			.select( weight, mom_age )
	end

	def self.birth_weight_to_tot_cigs
		o1at = Observation.arel_table	#	don't think that I can alias the initial table
		o2at = Observation.arel_table.alias('o2')
		o3at = Observation.arel_table.alias('o3')
		o4at = Observation.arel_table.alias('o4')
		o5at = Observation.arel_table.alias('o5')
		o6at = Observation.arel_table.alias('o6')

		weight = Arel::Nodes::NamedFunction.new("CAST", [o2at[:value].as("INT")], "weight")
		prepreg_cig = Arel::Nodes::NamedFunction.new("CAST", [o3at[:value].as("INT")], "prepreg_cig")
		first_cig = Arel::Nodes::NamedFunction.new("CAST", [o4at[:value].as("INT")], "first_cig")
		sec_cig = Arel::Nodes::NamedFunction.new("CAST", [o5at[:value].as("INT")], "sec_cig")
		last_cig = Arel::Nodes::NamedFunction.new("CAST", [o6at[:value].as("INT")], "last_cig")

#	Not quite there yet.
#		tot_cigs = Arel::Nodes::Addition.new(
#			Arel::Nodes::Addition.new(
#				Arel::Nodes::Addition.new(
#					Arel::Nodes::Multiplication.new(90,prepreg_cig),
#					Arel::Nodes::Multiplication.new(90,first_cig) ),
#					Arel::Nodes::Multiplication.new(90,sec_cig) ),
#					Arel::Nodes::Multiplication.new(90,last_cig) ).as('tot_cigs2')

		Observation
			.joins( outer(o2at, o1at[:chirp_id].eq(o2at[:chirp_id])) )
			.joins( outer(o3at, o1at[:chirp_id].eq(o3at[:chirp_id])) )
			.joins( outer(o4at, o1at[:chirp_id].eq(o4at[:chirp_id])) )
			.joins( outer(o5at, o1at[:chirp_id].eq(o5at[:chirp_id])) )
			.joins( outer(o6at, o1at[:chirp_id].eq(o6at[:chirp_id])) )
			.where( o1at[:concept].eq('birth_co') )
			.where( o1at[:value].eq('Washoe') )
			.where( o2at[:concept].eq 'DEM:Weight' )
			.where( o2at[:units].eq 'grams' )
			.where( o2at[:source_table].eq 'births' )
			.where( o3at[:concept].eq('prepreg_cig') )
			.where( o3at[:value].not_eq('99') )
			.where( o4at[:concept].eq('first_cig') )
			.where( o4at[:value].not_eq('99') )
			.where( o5at[:concept].eq('sec_cig') )
			.where( o5at[:value].not_eq('99') )
			.where( o6at[:concept].eq('last_cig') )
			.where( o6at[:value].not_eq('99') )
			.select( o1at[:chirp_id], weight, prepreg_cig, first_cig, sec_cig, last_cig,
				"( 90*CAST( o3.value AS INT ) + 90*CAST( o4.value AS INT ) + 90*CAST( o5.value AS INT ) + 90*CAST( o6.value AS INT ) ) AS tot_cigs" )	#, tot_cigs)

#	sadly no elegant arel way to add these columns found just yet
#	Could use Arel::Nodes::Addition.new(a,b) [only takes 2 so would have to do multiple times]

#			.select( o1at[:chirp_id], weight, prepreg_cig + first_cig )#, tot_cig )

	end

	def self.birth_weight_group_percents_to( field, as = nil )
		o1at = Observation.arel_table	#	don't think that I can alias the initial table
		o2at = o1at.alias('o2')
		o3at = o1at.alias('o3')

		grouping_table_name = 'grouping'

		grouping_sql = o1at
			.project( o1at[:value].as 'name' )
			.project( o1at[:value].count.as 'total' )
			.outer_join( o3at ).on( o1at[:chirp_id].eq( o3at[:chirp_id]))
			.where( o3at[:concept].eq('birth_co') )
			.where( o3at[:value].eq('Washoe') )
			.where( o1at[:concept].eq field )
			.group( o1at[:value] )
			.as( grouping_table_name )

		#	same name as in .as(...) above (to be used when selecting or whereing)
		grouping = Arel::Table.new( grouping_table_name )

		#	select before join, project after join (same thing)
		outside_select = Observation.from(grouping_sql.to_sql)
			.select( o1at[:value].as 'value' )
			.select( o1at[:value].count.as 'count' )
			.select( o2at[:value].as 'bwt_grp' )
			.select( grouping[:total].as 'total' )
			.outer_join( o1at ).on( o1at[:value].eq( grouping[:name]))
			.where( o1at[:concept].eq field )
			.where( o1at[:source_table].eq 'births' )
			.outer_join( o2at ).on( o1at[:chirp_id].eq( o2at[:chirp_id]))
			.where( o2at[:concept].eq 'bwt_grp' )
			.outer_join( o3at ).on( o1at[:chirp_id].eq( o3at[:chirp_id]))
			.where( o3at[:concept].eq('birth_co') )
			.where( o3at[:value].eq('Washoe') )
			.group( o1at[:value], o2at[:value], grouping[:total] )
			.order( o1at[:value] )

#	SELECT `observations`.`value`, 
#		COUNT(`observations`.`value`) AS count, 
#		`o2`.`value` AS bwt_grp, 
#		`grouping`.`total` AS group_total 
#	FROM (
#		SELECT `observations`.`value` AS name, COUNT(`observations`.`value`) AS total 
#		FROM `observations` 
#		WHERE `observations`.`concept` = 'DEM:Zip' 
#		GROUP BY `observations`.`value`
#	) grouping 
#	LEFT OUTER JOIN `observations` ON `observations`.`value` = `grouping`.`name` 
#	LEFT OUTER JOIN `observations` `o2` ON `observations`.`chirp_id` = `o2`.`chirp_id` 
#	WHERE `observations`.`concept` = 'DEM:Zip' AND `o2`.`concept` = 'bwt_grp' 
#	GROUP BY `observations`.`value`, `o2`.`value`

	end

	def self.birth_weight_group_to( field, as = nil )
		o1at = Observation.arel_table	#	don't think that I can alias the initial table
		o2at = Observation.arel_table.alias('o2')
		o3at = Observation.arel_table.alias('o3')

		Observation
			.joins( outer(o2at, o1at[:chirp_id].eq(o2at[:chirp_id])) )
			.joins( outer(o3at, o1at[:chirp_id].eq(o3at[:chirp_id])) )
			.where( o1at[:concept].eq 'bwt_grp' )
			.where( o1at[:source_table].eq 'births' )
			.where( o2at[:concept].eq field )
			.where( o2at[:source_table].eq 'births' )
			.where( o3at[:concept].eq('birth_co') )
			.where( o3at[:value].eq('Washoe') )
			.group( o1at[:value], o2at[:value] )
			.select( o1at[:value].as('bwt_grp'), o2at[:value] )
			.select( o1at[:chirp_id].count(:distinct).as('count') )
	end

	def self.birth_xy( x, y )
		o1at = Observation.arel_table	#	don't think that I can alias the initial table
		o2at = Observation.arel_table.alias('o2')
		o3at = Observation.arel_table.alias('o3')

		Observation
			.joins( outer(o2at, o1at[:chirp_id].eq(o2at[:chirp_id])) )
			.joins( outer(o3at, o1at[:chirp_id].eq(o3at[:chirp_id])) )
			.where( o1at[:concept].eq x )
			.where( o1at[:source_table].eq 'births' )
			.where( o2at[:concept].eq y )
			.where( o2at[:source_table].eq 'births' )
			.where( o3at[:concept].eq('birth_co') )
			.where( o3at[:value].eq('Washoe') )
			.group( o1at[:value], o2at[:value] )
			.select( o1at[:value].as('x'), o2at[:value].as('y') )
			.select( o1at[:chirp_id].count(:distinct).as('count') )
	end

end
