class Observation < ApplicationRecord

	def self.vaccination_count_by_year_month
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
