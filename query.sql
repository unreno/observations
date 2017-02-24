--DROP TABLE tempjoins;

--CREATE TEMPORARY TABLE tempjoins AS 

--	Sadly this takes about 45 seconds. SQL Server takes 2.
--	Actually, thats pretty impressive, but still slower than desired.
--	May need to implement something like sunspot.

--	This new versions takes about 10 seconds on mysql
--

--	Perhaps some use of IF would be faster?

--	SELECT DISTINCT o1.chirp_id, o1.value AS dob
--	FROM observations o1
--	LEFT JOIN observations o2 ON o1.chirp_id = o2.chirp_id
--	LEFT JOIN observations o3 ON o1.chirp_id = o3.chirp_id
--	LEFT JOIN observations o4 ON o1.chirp_id = o4.chirp_id
--	WHERE o1.concept = 'DEM:DOB' AND YEAR(o1.value) = 2015
--		AND o2.concept = 'birth_co' AND o2.value = 'Washoe'
--		AND o3.concept = 'mom_rco' AND o3.value = 'Washoe'
--		AND o4.concept = 'vaccination_desc'
--		AND o4.started_at < DATE_ADD(o1.value, INTERVAL 7 MONTH)
--		AND o4.value NOT IN (
--		'Hep B',
--		'DTAP',
--		'HIB', 
--		'HIB (2 dose)',
--		'PCV 13' , 
--		'IPV' , 
--		'Rotavirus (2 dose)' , 
--		'Rotavirus (3 dose)' )
--	GROUP BY chirp_id, o4.value

CREATE TEMPORARY TABLE tempjoins AS 
SELECT chirp_id, dob, SUM(hepb_count), SUM(dtap_count), SUM(hib2_count), SUM(hib3_count), SUM(pcv_count), SUM(ipv_count), SUM(r2_count), SUM(r3_count), SUM(other_count)
FROM (
	SELECT DISTINCT o1.chirp_id, o1.value AS dob, 
		IF( o4.value = 'Hep B',  COUNT(1), NULL ) AS hepb_count,
		IF( o4.value = 'DTAP' , COUNT(1), NULL ) AS dtap_count,
		IF( o4.value = 'HIB' , COUNT(1), NULL ) AS hib3_count,
		IF( o4.value = 'HIB (2 dose)' , COUNT(1), NULL ) AS hib2_count,
		IF( o4.value = 'PCV 13' , COUNT(1), NULL ) AS pcv_count,
		IF( o4.value = 'IPV' , COUNT(1), NULL ) AS ipv_count,
		IF( o4.value = 'Rotavirus (2 dose)' , COUNT(1), NULL ) AS r2_count,
		IF( o4.value = 'Rotavirus (3 dose)' , COUNT(1), NULL ) AS r3_count
	FROM observations o1
	LEFT JOIN observations o2 ON o1.chirp_id = o2.chirp_id
	LEFT JOIN observations o3 ON o1.chirp_id = o3.chirp_id
	LEFT JOIN observations o4 ON o1.chirp_id = o4.chirp_id
	WHERE o1.concept = 'DEM:DOB' AND YEAR(o1.value) = 2015
		AND o2.concept = 'birth_co' AND o2.value = 'Washoe'
		AND o3.concept = 'mom_rco' AND o3.value = 'Washoe'
		AND o4.concept = 'vaccination_desc'
		AND o4.started_at < DATE_ADD(o1.value, INTERVAL 7 MONTH)
	GROUP BY chirp_id, o4.value
) xyz
GROUP BY chirp_id;

--		CASE WHEN o4.value = 'Heb B' THEN COUNT(1)
--		ELSE NULL END AS hepb_count,
--		CASE WHEN o4.value = 'DTAP' THEN COUNT(1)
--		ELSE NULL END AS dtap_count,
--		CASE WHEN o4.value = 'HIB' THEN COUNT(1)
--		ELSE NULL END AS hib3_count,
--		CASE WHEN o4.value = 'HIB (2 dose)' THEN COUNT(1)
--		ELSE NULL END AS hib2_count,
--		CASE WHEN o4.value = 'PCV 13' THEN COUNT(1)
--		ELSE NULL END AS pcv_count,
--		CASE WHEN o4.value = 'IPV' THEN COUNT(1)
--		ELSE NULL END AS ipv_count,
--		CASE WHEN o4.value = 'Rotavirus (2 dose)' THEN COUNT(1)
--		ELSE NULL END AS r2_count,
--		CASE WHEN o4.value = 'Rotavirus (3 dose)' THEN COUNT(1)
--		ELSE NULL END AS r3_count

--	SELECT *
--	FROM tempjoins
--	WHERE dtap_count >= 3
--		AND ipv_count >= 2
--		AND pcv_count >= 3 
--		AND hepb_count >= 2
--		AND ( hib2_count >= 2 OR hib3_count >= 3 )
--		AND ( r2_count >= 2 OR r3_count >= 3 );

