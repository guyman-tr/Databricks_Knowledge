-- obtain the proper ID value for a datasource for URL purposes
SELECT MIN(dc.id) AS "id", dc.datasource_id
FROM data_connections AS dc
	INNER JOIN datasources AS dc_d
		ON dc.datasource_id = dc_d.id
			AND dc_d.connectable = true
GROUP BY dc.datasource_id