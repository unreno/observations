$sql =<<EOF
SELECT chirp_id, dob, SUM(dtap) AS dtap_count, SUM(hepb) AS hepb_count,
	SUM(hib2) AS hib2_count, SUM(hib3) AS hib3_count, SUM(pcv) AS pcv_count,
	SUM(ipv) AS ipv_count, SUM(r2) AS r2_count, SUM(r3) AS r3_count
FROM (
	SELECT o1.chirp_id, o1.value AS dob,
		IF( o4.value = 'Hep B',  1, 0 ) AS hepb,
		IF( o4.value = 'DTAP' , 1, 0 ) AS dtap,
		IF( o4.value = 'HIB' , 1, 0 ) AS hib3,
		IF( o4.value = 'HIB (2 dose)' , 1, 0 ) AS hib2,
		IF( o4.value = 'PCV 13' , 1, 0 ) AS pcv,
		IF( o4.value = 'IPV' , 1, 0 ) AS ipv,
		IF( o4.value = 'Rotavirus (2 dose)' , 1, 0 ) AS r2,
		IF( o4.value = 'Rotavirus (3 dose)' , 1, 0 ) AS r3
	FROM observations o1
	LEFT JOIN observations o2 ON o1.chirp_id = o2.chirp_id
	LEFT JOIN observations o3 ON o1.chirp_id = o3.chirp_id
	LEFT JOIN observations o4 ON o1.chirp_id = o4.chirp_id
	WHERE o1.concept = 'DEM:DOB' AND YEAR(o1.value) = 2015
		AND o2.concept = 'birth_co' AND o2.value = 'Washoe'
		AND o3.concept = 'mom_rco' AND o3.value = 'Washoe'
		AND o4.concept = 'vaccination_desc'
		AND o4.started_at < DATE_ADD(o1.value, INTERVAL 7 MONTH)
	GROUP BY o1.chirp_id, o4.value, o4.started_at
) xyz
GROUP BY chirp_id, dob;
EOF

