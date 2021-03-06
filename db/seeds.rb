# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)



#	require 'csv'
#	
#	(CSV.open( 'misc/Observations-20161219.csv', 'r:bom|utf-8', headers: true )).each do |line|
#	#	puts ([infilename] + all_uniq_columns.collect{|c|line[c]}).to_csv
#		puts line.inspect
#	
#	#id,chirp_id,provider_id,concept,started_at,ended_at,value,units,raw,downloaded_at,source_schema,source_table,source_id,imported_at
#	#"1","2068016622","0","ac_anemia","2015-01-01 00:00:00.000","2015-01-01 00:00:00.000","No","","2","2016-11-28 16:41:20.420","vital","births","268","2016-11-28 16:43:03.257"
#		Observation.create!(
#			id: line['id'],
#			chirp_id: line['chirp_id'],
#			provider_id: line['provider_id'],
#			concept: line['concept'],
#			started_at: line['started_at'],
#			ended_at: line['ended_at'],
#			value: line['value'],
#			units: line['units'],
#			raw: line['raw'],
#			downloaded_at: line['downloaded_at'],
#			source_schema: line['source_schema'],
#			source_table: line['source_table'],
#			source_id: line['source_id'],
#			imported_at: line['imported_at']
#		)
#	end

#	The above is just WAY TOO LONG. The following takes about 3 seconds.



filename="Observations-20170712.tsv"


if ActiveRecord::Base.connection_config[:adapter] == 'sqlserver'
	sql =<<-EOF
	DECLARE @bulk_cmd VARCHAR(1000) = 'BULK INSERT observations 
	FROM ''/home/jakewendt/github/unreno/observations/misc/#{filename}'' 
	WITH ( ROWTERMINATOR = '''+CHAR(10)+''', FIRSTROW = 2, TABLOCK)';
	EXEC(@bulk_cmd);
	EOF
	puts sql
elsif ActiveRecord::Base.connection_config[:adapter] == 'mysql2'
	sql =<<-EOF
	LOAD DATA LOCAL INFILE 'misc/#{filename}' INTO TABLE observations
	LINES TERMINATED BY '\r\n'
	IGNORE 1 LINES;
	EOF
	puts sql
end

#	BEWARE! THIS DOES NOT APPEND! 
#	As it includes the ID, it will try and fail to
#	overwrite the records and fails silently.
ActiveRecord::Base.connection.execute(sql);



#USE [observations_production]
#GO
#DECLARE @bulk_cmd VARCHAR(1000) = 'BULK INSERT observations FROM ''/home/jakewendt/github/unreno/observations/misc/Observations-20170302.tsv'' WITH ( ROWTERMINATOR = '''+CHAR(10)+''', FIRSTROW = 2, TABLOCK)';
#EXEC(@bulk_cmd);
#GO


