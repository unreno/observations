class Observation < ApplicationRecord
	#
	#	Can't alias initial table unless, start with arel_table and end with find_by_sql (or the like)
	#
	#	They REALLY don't want you to alias that first table.
	#	Its all behind the scenes so it really doesn't matter much.
	#
	def self.meddling
		o1=Observation.arel_table # same as o1=Arel::Table.new('observations'), can't alias
		o2=o1.alias('o2')
		o3=o1.alias('o3')
		o4=o1.alias('o4')
		inside = o1.join(o2,Arel::Nodes::OuterJoin).on(o1[:chirp_id].eq(o2[:chirp_id]))
			.join(o3,Arel::Nodes::OuterJoin).on(o1[:chirp_id].eq(o3[:chirp_id]))
			.join(o4,Arel::Nodes::OuterJoin).on(o1[:chirp_id].eq(o4[:chirp_id]))
			.where(o1[:concept].eq('DEM:DOB'))
			.where(o1[:value].matches('2015%'))
			.where(o2[:concept].eq('birth_co'))
			.where(o2[:value].eq('Washoe'))
			.where(o3[:concept].eq('mom_rco'))
			.where(o3[:value].eq('Washoe'))
			.where(o4[:concept].eq('vaccination_desc'))
			.project(o1[:chirp_id])
			.project(o1[:value].as('dob'))
			.project(o4[:started_at])
			.project(o4[:value].as('vaccination'))
			.distinct		#	done to drop any duplicates

#			.group(o4[:chirp_id],o4[:value])	#	for aggregating


#			.group(o4[:chirp_id],o4[:value],o4[:started_at])	#	done to drop any duplicates

#			.project("sum(case when `o4`.`value` = 'DTap' then 1 else 0 end) as dtap_count")
#			.project("sum(case when `o4`.`value` = 'Hep B' then 1 else 0 end) as hepb_count")
#			.project("sum(case when `o4`.`value` = 'IPV' then 1 else 0 end) as ipv_count")
#			.take(100)
#	This seems cleaner, but it does exactly the same thing
#	However, it may be easier to nest.


#		(o2=Observation.arel_table).table_alias='o2'
#		o1.join(o2,Arel::Nodes::OuterJoin).on(o1[:chirp_id].eq(o2[:chirp_id])).to_sql
##=> "SELECT FROM `observations` `o2` LEFT OUTER JOIN `observations` `o2` ON `o2`.`chirp_id` = `o2`.`chirp_id`"
#
#	sql = Observation.expected_immunizations.to_sql
#	INNER is sql reserved word. DON'T USE IT!
		Observation.from(Arel.sql("(#{inside.to_sql}) AS inside"))
			.group("chirp_id,dob")
			.select('chirp_id, dob')
			.project("SUM(CASE WHEN vaccination = 'DTAP' THEN 1 ELSE 0 END) AS dtap_count")
			.project("SUM(CASE WHEN vaccination = 'Hep B' THEN 1 ELSE 0 END) AS hepb_count")
			.project("SUM(CASE WHEN vaccination = 'HIB (2 dose)' THEN 1 ELSE 0 END) AS hib2_count")
			.project("SUM(CASE WHEN vaccination = 'HIB' THEN 1 ELSE 0 END) AS hib3_count")
			.project("SUM(CASE WHEN vaccination = 'PCV 13' THEN 1 ELSE 0 END) AS pcv_count")
			.project("SUM(CASE WHEN vaccination = 'IPV' THEN 1 ELSE 0 END) AS ipv_count")
			.project("SUM(CASE WHEN vaccination = 'Rotavirus (2 dose)' THEN 1 ELSE 0 END) AS r2_count")
			.project("SUM(CASE WHEN vaccination = 'Rotavirus (3 dose)' THEN 1 ELSE 0 END) AS r3_count")

	end

	def self.expected_immunizations
		o1at = Observation.arel_table	#	don't think that I can alias the initial table
		o2at = Observation.arel_table.alias('o2')
		o3at = Observation.arel_table.alias('o3')
		o4at = Observation.arel_table.alias('o4')

		results = Observation
			.joins( Arel::Nodes::OuterJoin.new(o2at, Arel::Nodes::On.new(
				o1at[:chirp_id].eq(o2at[:chirp_id])
			)))
			.joins( Arel::Nodes::OuterJoin.new(o3at, Arel::Nodes::On.new(
				o1at[:chirp_id].eq(o3at[:chirp_id])
			)))
			.joins( Arel::Nodes::OuterJoin.new(o4at, Arel::Nodes::On.new(
				o1at[:chirp_id].eq(o4at[:chirp_id])
			)))
			.where(o1at[:concept].eq('DEM:DOB'))
			.where(o1at[:value].matches('2015%'))
			.where(o2at[:concept].eq('birth_co'))
			.where(o2at[:value].eq('Washoe'))
			.where(o3at[:concept].eq('mom_rco'))
			.where(o3at[:value].eq('Washoe'))
			.where(o4at[:concept].eq('vaccination_desc'))
			.select(o1at[:chirp_id])
			.select(o1at[:value].as('dob'))
			.group(o4at[:chirp_id],o4at[:value],o4at[:started_at])	#	done to drop any duplicates

		#	Not agnostic :(
		results = if ActiveRecord::Base.connection_config[:adapter] == 'sqlserver'
			results.where("[o4].[started_at] < DATEADD(month, 7, [observations].[value])")
				.select("CASE WHEN o4.value = 'Hep B' THEN 1 ELSE 0 END AS hepb")
				.select("CASE WHEN o4.value = 'DTAP' THEN 1 ELSE 0 END AS dtap")
				.select("CASE WHEN o4.value = 'HIB (2 dose)' THEN 1 ELSE 0 END AS hib2")
				.select("CASE WHEN o4.value = 'HIB (3 dose)' THEN 1 ELSE 0 END AS hib3")
				.select("CASE WHEN o4.value = 'PCV 13' THEN 1 ELSE 0 END AS pcv")
				.select("CASE WHEN o4.value = 'IPV' THEN 1 ELSE 0 END AS ipv")
				.select("CASE WHEN o4.value = 'Rotavirus (2 dose)' THEN 1 ELSE 0 END AS r2")
				.select("CASE WHEN o4.value = 'Rotavirus (3 dose)' THEN 1 ELSE 0 END AS r3")
		elsif ActiveRecord::Base.connection_config[:adapter] == 'mysql2'
			results.where("`o4`.`started_at` < DATE_ADD(`observations`.`value`,INTERVAL 7 MONTH)")
				.select("IF( o4.value = 'Hep B', 1, 0 ) AS hepb")
				.select("IF( o4.value = 'DTAP', 1, 0 ) AS dtap")
				.select("IF( o4.value = 'HIB (2 dose)', 1, 0 ) AS hib2")
				.select("IF( o4.value = 'HIB (3 dose)', 1, 0 ) AS hib3")
				.select("IF( o4.value = 'PCV 13', 1, 0 ) AS pcv")
				.select("IF( o4.value = 'IPV', 1, 0 ) AS ipv")
				.select("IF( o4.value = 'Rotavirus (2 dose)', 1, 0 ) AS r2")
				.select("IF( o4.value = 'Rotavirus (3 dose)', 1, 0 ) AS r3")
		else
			raise "I'm confused"
		end


#	sql = Observation.expected_immunizations.to_sql
#	Observation.from(Arel.sql("(#{sql}) as asdf")).group("chirp_id,dob").select('chirp_id, dob, SUM(dtap) AS dtap_count, SUM(hepb) AS hepb_count')


#DROP TABLE tempjoins;
#
#CREATE TEMPORARY TABLE tempjoins AS 
#SELECT chirp_id, dob, SUM(dtap) AS dtap_count, SUM(hepb) AS hepb_count,
#	SUM(hib2) AS hib2_count, SUM(hib3) AS hib3_count, SUM(pcv) AS pcv_count,
#	SUM(ipv) AS ipv_count, SUM(r2) AS r2_count, SUM(r3) AS r3_count
#FROM (


#) xyz
#GROUP BY chirp_id, dob;
#
#SELECT *
#FROM tempjoins
#WHERE dtap_count >= 3
#	AND ipv_count >= 2
#	AND pcv_count >= 3 
#	AND hepb_count >= 2
#	AND ( hib2_count >= 2 OR hib3_count >= 3 )
#	AND ( r2_count >= 2 OR r3_count >= 3 );

	end


	def self.total_vaccination_counts
		o1at = Observation.arel_table	#	don't think that I can alias the initial table
		o2at = Observation.arel_table.alias('o2')

		#	why union? Just do multiple queries and join the results in ruby

		observations = Observation
			.where(o1at[:concept].eq('DEM:DOB'))
			.where(o1at[:value].matches('2015%'))
			.select("'Total Distinct CHIRP IDs' AS vaccination, COUNT( DISTINCT chirp_id ) AS count")
			.to_a

		observations += Observation
			.joins( Arel::Nodes::OuterJoin.new(o2at, Arel::Nodes::On.new(
				o1at[:chirp_id].eq(o2at[:chirp_id])
			)))
			.where(o1at[:concept].eq('DEM:DOB'))
			.where(o1at[:value].matches('2015%'))
			.where(o2at[:concept].eq('vaccination_desc'))
			.select("'CHIRP IDs with WebIZ Match' AS vaccination, COUNT( DISTINCT o2.chirp_id ) AS count")
			.to_a

		observations += Observation
			.joins( Arel::Nodes::OuterJoin.new(o2at, Arel::Nodes::On.new(
				o1at[:chirp_id].eq(o2at[:chirp_id])
			)))
			.where(o1at[:concept].eq('DEM:DOB'))
			.where(o1at[:value].matches('2015%'))
			.where(o2at[:concept].eq('vaccination_desc'))
			.select(o2at[:value].as('vaccination'),"COUNT( DISTINCT o2.chirp_id ) AS count")
			.group(o2at[:value])

		observations.sort_by{|o| o.count }.reverse
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
			.joins( Arel::Nodes::OuterJoin.new(o2at, Arel::Nodes::On.new(
				o1at[:chirp_id].eq(o2at[:chirp_id])
			)))
			.joins( Arel::Nodes::OuterJoin.new(o3at, Arel::Nodes::On.new(
				o1at[:chirp_id].eq(o3at[:chirp_id])
			)))
			.where(o1at[:concept].eq('DEM:DOB'))
			.where(o1at[:value].matches('2015%'))
			.where(o2at[:concept].eq('birth_co'))
			.where(o2at[:value].eq('Washoe'))
			.where(o3at[:concept].eq('vaccination_desc'))
			.group( group_year_vac, group_month_vac )
			.order( group_year_vac, group_month_vac )
			.select( year_vac, month_vac )
			.select("COUNT(1) AS count")
	end

end
