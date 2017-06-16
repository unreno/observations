

DELETE FROM observations WHERE concept = 'UNR:BirthWeightGroup';
DELETE FROM observations WHERE concept = 'birth_weight_group';

--	One of the reports is expecting only Very Low, Low and Normal (text as returned below)

INSERT INTO observations
( chirp_id, provider_id, concept, started_at, ended_at, value, units, raw, downloaded_at, source_schema, source_table, source_id, imported_at )
SELECT chirp_id, provider_id, 'birth_weight_group', started_at, ended_at,
CASE 
	WHEN value >= 2500 THEN 'Normal Birth Weight (>=2,500g, <=8,000g)'
	WHEN value >= 1500 THEN 'Low Birth Weight (>=1,500g, <2,500g)'
	ELSE 'Very Low Birth Weight (<1,500g)'
END , '', value, downloaded_at, source_schema, source_table, source_id, imported_at
FROM observations
WHERE concept = 'birth_weight_grams' AND value < 8888;

--	WHEN value =  9999 THEN 'Unknown 9999'
--	WHEN value =  8888 THEN 'Unknown 8888'
--	WHEN value >  8000 THEN 'High Birth Weight (> 8,000g)'
--	WHEN value >= 1000 THEN 'Very Low Birth Weight (<1,500g)'
--	ELSE NULL	--	'Extremely Low Birth Weight'

SELECT value, COUNT(1) FROM observations WHERE concept = 'birth_weight_group' GROUP BY value;

