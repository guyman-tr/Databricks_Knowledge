--used only to obtain a min data_connection_id for hyperlinks
SELECT
  MIN(dc.id)                     AS "data_connection_id",
  CAST('Data Source' AS TEXT)    AS "item_type", 
  dc.datasource_id
FROM data_connections AS dc
  INNER JOIN datasources AS dc_d
      ON dc.datasource_id = dc_d.id
          AND dc_d.connectable = true
GROUP BY dc.datasource_id