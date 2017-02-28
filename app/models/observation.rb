class Observation < ApplicationRecord

	def self.total_vaccination_counts
		o1at = Observation.arel_table	#	don't think that I can alias the initial table
		o2at = Observation.arel_table.alias('o2')

#	why union? Just do multiple queries and join the results in ruby

		observations = Observation
			.where(o1at[:concept].eq('DEM:DOB'))
			.where(o1at[:value].matches('2015%'))
			.select("'Total Distinct CHIRP IDs' AS vaccination, COUNT( DISTINCT chirp_id ) AS count")

#		Observation
#			.joins( Arel::Nodes::OuterJoin.new(o2at, Arel::Nodes::On.new(
#				o1at[:chirp_id].eq(o2at[:chirp_id])
#			)))
#			.where(o1at[:concept].eq('DEM:DOB'))
#			.where(o1at[:value].matches('2015%'))
#			.where(o2at[:concept].eq('vaccination_desc'))
#			.select("'CHIRP IDs with WebIZ Match' AS vaccination, COUNT( DISTINCT chirp_id ) AS count")

#		Observation
#			.joins( Arel::Nodes::OuterJoin.new(o2at, Arel::Nodes::On.new(
#				o1at[:chirp_id].eq(o2at[:chirp_id])
#			)))
#			.where(o1at[:concept].eq('DEM:DOB'))
#			.where(o1at[:value].matches('2015%'))
#			.where(o2at[:concept].eq('vaccination_desc'))
#			.select(o2at[:value],"COUNT( DISTINCT o2.chirp_id ) AS count)
#			.group(o2at[:value])

			
#SELECT g, count FROM (

#	SELECT 'Total Distinct CHIRP IDs' AS g, COUNT( DISTINCT chirp_id ) AS count
#	FROM dbo.observations
#	WHERE concept = 'DEM:DOB' AND value BETWEEN '2015-01-01' AND '2015-12-31'
#UNION

#	SELECT 'CHIRP IDs with WebIZ Match' AS g, COUNT( DISTINCT o1.chirp_id ) AS count
#	FROM dbo.observations o1
#	JOIN dbo.observations o2 ON o1.chirp_id = o2.chirp_id
#	WHERE o1.concept = 'DEM:DOB' AND o1.value BETWEEN '2015-01-01' AND '2015-12-31'
#		AND o2.concept = 'vaccination_desc'
#UNION
#	SELECT o2.value AS g, COUNT( DISTINCT o2.chirp_id ) AS count
#	FROM dbo.observations o1
#	JOIN dbo.observations o2 ON o1.chirp_id = o2.chirp_id
#	WHERE o1.concept = 'DEM:DOB' AND o1.value BETWEEN '2015-01-01' AND '2015-12-31'
#		AND o2.concept = 'vaccination_desc'
#	GROUP BY o2.value
#) all_groups
#ORDER BY count ASC
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
