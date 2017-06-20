

DELETE FROM observations WHERE concept = 'DEM:ZIP';


INSERT INTO observations
( chirp_id, provider_id, concept, started_at, ended_at, value, units, raw, downloaded_at, source_schema, source_table, source_id, imported_at )
SELECT chirp_id, provider_id, 'DEM:ZIP', started_at, ended_at, value,
	'', value, downloaded_at, source_schema, source_table, source_id, imported_at
FROM observations
WHERE concept = 'birth_zip';

SELECT value, COUNT(1) FROM observations WHERE concept = 'DEM:ZIP' GROUP BY value;


