--DROP TABLE tempjoins;

--CREATE TEMPORARY TABLE tempjoins AS 

--	Sadly this takes about 45 seconds. SQL Server takes 2.
--	Actually, thats pretty impressive, but still slower than desired.
--	May need to implement something like sunspot.

EXPLAIN SELECT o.chirp_id, o.dob, 
	dtap_count, hepb_count, hib2_count, hib3_count, pcv_count, ipv_count, r2_count, r3_count
FROM (
	SELECT DISTINCT o1.chirp_id, o1.value AS dob
	FROM observations o1
	LEFT JOIN observations o2 ON o1.chirp_id = o2.chirp_id
	LEFT JOIN observations o3 ON o1.chirp_id = o3.chirp_id
	LEFT JOIN observations o4 ON o1.chirp_id = o4.chirp_id
	WHERE o1.concept = 'DEM:DOB' AND YEAR(o1.value) = 2015
		AND o2.concept = 'birth_co' AND o2.value = 'Washoe'
		AND o3.concept = 'mom_rco' AND o3.value = 'Washoe'
		AND o4.concept = 'vaccination_desc'
) o
LEFT JOIN (
	SELECT chirp_id, COUNT(1) AS dtap_count FROM (
		SELECT o4.chirp_id, o4.started_at
		FROM observations o1
		LEFT JOIN observations o4 ON o1.chirp_id = o4.chirp_id
		WHERE o1.concept = 'DEM:DOB' AND YEAR(o1.value) = 2015
			AND o4.concept = 'vaccination_desc' AND o4.value = 'DTaP'
			AND o4.started_at < DATE_ADD(o1.value, INTERVAL 7 MONTH)
		GROUP BY o4.chirp_id, o4.started_at
	)	a1
	GROUP BY chirp_id
) v1 ON o.chirp_id = v1.chirp_id
LEFT JOIN (
	SELECT chirp_id, COUNT(1) AS hepb_count FROM (
		SELECT o4.chirp_id, o4.started_at
		FROM observations o1
		LEFT JOIN observations o4 ON o1.chirp_id = o4.chirp_id
		WHERE o1.concept = 'DEM:DOB' AND YEAR(o1.value) = 2015
			AND o4.concept = 'vaccination_desc' AND o4.value = 'Hep B'
			AND o4.started_at < DATE_ADD(o1.value, INTERVAL 7 MONTH)
		GROUP BY o4.chirp_id, o4.started_at
	) a1
	GROUP BY chirp_id
) v2 ON o.chirp_id = v2.chirp_id
LEFT JOIN (
	SELECT chirp_id, COUNT(1) AS hib3_count FROM (
		SELECT o4.chirp_id, o4.started_at
		FROM observations o1
		LEFT JOIN observations o4 ON o1.chirp_id = o4.chirp_id
		WHERE o1.concept = 'DEM:DOB' AND YEAR(o1.value) = 2015
			AND o4.concept = 'vaccination_desc' AND o4.value = 'HIB'
			AND o4.started_at < DATE_ADD(o1.value, INTERVAL 7 MONTH)
		GROUP BY o4.chirp_id, o4.started_at
	) a1
	GROUP BY chirp_id
) v3 ON o.chirp_id = v3.chirp_id
LEFT JOIN (
	SELECT chirp_id, COUNT(1) AS hib2_count FROM (
		SELECT o4.chirp_id, o4.started_at
		FROM observations o1
		LEFT JOIN observations o4 ON o1.chirp_id = o4.chirp_id
		WHERE o1.concept = 'DEM:DOB' AND YEAR(o1.value) = 2015
			AND o4.concept = 'vaccination_desc' AND o4.value = 'HIB (2 dose)'
			AND o4.started_at < DATE_ADD(o1.value, INTERVAL 7 MONTH)
		GROUP BY o4.chirp_id, o4.started_at
	) a1
	GROUP BY chirp_id
) v4 ON o.chirp_id = v4.chirp_id
LEFT JOIN (
	SELECT chirp_id, COUNT(1) AS pcv_count FROM (
		SELECT o4.chirp_id, o4.started_at
		FROM observations o1
		LEFT JOIN observations o4 ON o1.chirp_id = o4.chirp_id
		WHERE o1.concept = 'DEM:DOB' AND YEAR(o1.value) = 2015
			AND o4.concept = 'vaccination_desc' AND o4.value = 'PCV 13'
			AND o4.started_at < DATE_ADD(o1.value, INTERVAL 7 MONTH)
		GROUP BY o4.chirp_id, o4.started_at
	) a1
	GROUP BY chirp_id
) v5 ON o.chirp_id = v5.chirp_id
LEFT JOIN (
	SELECT chirp_id, COUNT(1) AS ipv_count FROM (
		SELECT o4.chirp_id, o4.started_at
		FROM observations o1
		LEFT JOIN observations o4 ON o1.chirp_id = o4.chirp_id
		WHERE o1.concept = 'DEM:DOB' AND YEAR(o1.value) = 2015
			AND o4.concept = 'vaccination_desc' AND o4.value = 'IPV'
			AND o4.started_at < DATE_ADD(o1.value, INTERVAL 7 MONTH)
		GROUP BY o4.chirp_id, o4.started_at
	) a1
	GROUP BY chirp_id
) v6 ON o.chirp_id = v6.chirp_id
LEFT JOIN (
	SELECT chirp_id, COUNT(1) AS r2_count FROM (
		SELECT o4.chirp_id, o4.started_at
		FROM observations o1
		LEFT JOIN observations o4 ON o1.chirp_id = o4.chirp_id
		WHERE o1.concept = 'DEM:DOB' AND YEAR(o1.value) = 2015
			AND o4.concept = 'vaccination_desc' AND o4.value = 'Rotavirus (2 dose)'
			AND o4.started_at < DATE_ADD(o1.value, INTERVAL 7 MONTH)
		GROUP BY o4.chirp_id, o4.started_at
	) a1
	GROUP BY chirp_id
) v7 ON o.chirp_id = v7.chirp_id
LEFT JOIN (
	SELECT chirp_id, COUNT(1) AS r3_count FROM (
		SELECT o4.chirp_id, o4.started_at
		FROM observations o1
		LEFT JOIN observations o4 ON o1.chirp_id = o4.chirp_id
		WHERE o1.concept = 'DEM:DOB' AND YEAR(o1.value) = 2015
			AND o4.concept = 'vaccination_desc' AND o4.value = 'Rotavirus (3 dose)'
			AND o4.started_at < DATE_ADD(o1.value, INTERVAL 7 MONTH)
		GROUP BY o4.chirp_id, o4.started_at
	) a1
	GROUP BY chirp_id
) v8 ON o.chirp_id = v8.chirp_id;


--	SELECT *
--	FROM tempjoins
--	WHERE dtap_count >= 3
--		AND ipv_count >= 2
--		AND pcv_count >= 3 
--		AND hepb_count >= 2
--		AND ( hib2_count >= 2 OR hib3_count >= 3 )
--		AND ( r2_count >= 2 OR r3_count >= 3 );

