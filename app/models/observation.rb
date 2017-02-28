class Observation < ApplicationRecord


#DROP TABLE tempjoins;
#
#CREATE TEMPORARY TABLE tempjoins AS 
#SELECT chirp_id, dob, SUM(dtap) AS dtap_count, SUM(hepb) AS hepb_count,
#	SUM(hib2) AS hib2_count, SUM(hib3) AS hib3_count, SUM(pcv) AS pcv_count,
#	SUM(ipv) AS ipv_count, SUM(r2) AS r2_count, SUM(r3) AS r3_count
#FROM (
#	SELECT o1.chirp_id, o1.value AS dob,
#		IF( o4.value = 'Hep B',  1, 0 ) AS hepb,
#		IF( o4.value = 'DTAP' , 1, 0 ) AS dtap,
#		IF( o4.value = 'HIB' , 1, 0 ) AS hib3,
#		IF( o4.value = 'HIB (2 dose)' , 1, 0 ) AS hib2,
#		IF( o4.value = 'PCV 13' , 1, 0 ) AS pcv,
#		IF( o4.value = 'IPV' , 1, 0 ) AS ipv,
#		IF( o4.value = 'Rotavirus (2 dose)' , 1, 0 ) AS r2,
#		IF( o4.value = 'Rotavirus (3 dose)' , 1, 0 ) AS r3
#	FROM observations o1
#	LEFT JOIN observations o2 ON o1.chirp_id = o2.chirp_id
#	LEFT JOIN observations o3 ON o1.chirp_id = o3.chirp_id
#	LEFT JOIN observations o4 ON o1.chirp_id = o4.chirp_id
#	WHERE o1.concept = 'DEM:DOB' AND YEAR(o1.value) = 2015
#		AND o2.concept = 'birth_co' AND o2.value = 'Washoe'
#		AND o3.concept = 'mom_rco' AND o3.value = 'Washoe'
#		AND o4.concept = 'vaccination_desc'
#		AND o4.started_at < DATE_ADD(o1.value, INTERVAL 7 MONTH)
#	GROUP BY o1.chirp_id, o4.value, o4.started_at
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

		@results = Observation
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
