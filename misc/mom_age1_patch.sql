

DELETE FROM observations WHERE concept = 'UNR:MotherAgeGroup';
DELETE FROM observations WHERE concept = 'mother_age_group';


INSERT INTO observations
( chirp_id, provider_id, concept, started_at, ended_at, value, units, raw, downloaded_at, source_schema, source_table, source_id, imported_at )
SELECT chirp_id, provider_id, 'mother_age_group', started_at, ended_at,
CASE 
	WHEN value >= 45 THEN '45+'
	WHEN value >= 40 THEN '40-44'
	WHEN value >= 35 THEN '35-39'
	WHEN value >= 30 THEN '30-34'
	WHEN value >= 25 THEN '25-29'
	WHEN value >= 20 THEN '20-24'
	WHEN value >= 18 THEN '18-19'
	WHEN value >= 15 THEN '15-17'
	WHEN value >= 10 THEN '10-14'
	ELSE 'Under 10'
END , '', value, downloaded_at, source_schema, source_table, source_id, imported_at
FROM observations
WHERE concept = 'b2_mother_age';

SELECT value, COUNT(1) FROM observations WHERE concept = 'mother_age_group' GROUP BY value;

