class ReportsController < ApplicationController
  def montly_birth_counts
  end

	def vaccination_count
#
#SELECT YEAR(o3.started_at), MONTH(o3.started_at), COUNT(1) AS count
#FROM dbo.observations o1
#LEFT JOIN dbo.observations o2 ON o1.chirp_id = o2.chirp_id
#LEFT JOIN dbo.observations o3 ON o1.chirp_id = o3.chirp_id
#WHERE o1.concept = 'DEM:DOB' AND DATEPART(year,o1.value) = 2015
#	AND o2.concept = 'birth_co' AND o2.value = 'Washoe'
#	AND o3.source_schema = 'WebIZ' AND o3.concept = 'vaccination_desc'
#GROUP BY YEAR(o3.started_at), MONTH(o3.started_at)
#ORDER BY YEAR(o3.started_at), MONTH(o3.started_at)
#
#
#birth year | birth month | vaccination record count
#-----------|-------------|--------------------------
#2015 | 1 | 394
#2015 | 2 | 329
#2015 | 3 | 2143
#...
#
#		o1at = Observation.arel_table.alias('o1')
#		o2at = Observation.arel_table.alias('o2')
#		o3at = Observation.arel_table.alias('o3')


#	https://github.com/rails/arel#complex-joins

	end
end
