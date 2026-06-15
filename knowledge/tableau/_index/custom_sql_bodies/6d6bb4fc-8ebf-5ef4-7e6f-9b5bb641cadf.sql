-- obtain the proper ID value for a datasource for URL purposes
SELECT
    MIN(dc.id)          AS "id" ,
    MIN(dc.owner_type)  AS "owner_type" ,
    MIN(dc.server)      AS "server" ,
    dc_d.id             AS "datasource_id"
FROM data_connections AS dc
	INNER JOIN datasources AS dc_d
		ON dc.owner_type = 'Datasource'
            AND dc.owner_id = dc_d.id
			AND dc_d.connectable = true
GROUP BY
    dc_d.id