USE CATALOG dwh_daily_process;
USE SCHEMA migration_tables;



CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.DWH_ColumnstoreTablesMaintenance(
IN V_SchemaName STRING)
LANGUAGE SQL
SQL SECURITY INVOKER
MODIFIES SQL DATA
AS

BEGIN


  
DECLARE V_date TIMESTAMP ;

DECLARE V_sql STRING ;
-- EXEC sys.sp_set_session_context @key = 'wlm_context', @value = 'REBUILD';

SET V_date = current_timestamp()
;

SET V_sql = (
SELECT
ARRAY_JOIN(COLLECT_LIST(cast ( `Rebuild_Index_SQL` as STRING)), '; ') FROM (

		SELECT 
	 		 s.name AS `Schema_Name`
			,t.name AS `Table_Name`
			,rg.partition_number AS `Partition_Number`
			,`par_count`
			,SUM(rg.total_rows) AS `Total_Rows`
			,SUM(CASE WHEN rg.State = 1 THEN rg.Total_rows Else 0 END) AS `Rows_in_OPEN_Row_Groups`
			,SUM(CASE WHEN rg.State = 2 THEN rg.Total_Rows ELSE 0 END) AS `Rows_in_Closed_Row_Groups`
			,SUM(CASE WHEN rg.State = 3 THEN rg.Total_Rows ELSE 0 END) AS `Rows_in_COMPRESSED_Row_Groups`
			,SUM(rg.deleted_rows) deleted_rows
			, ' ' END  AS `Rebuild_Index_SQL`
		FROM sys.pdw_nodes_column_store_row_groups rg
		  JOIN sys.pdw_nodes_tables pt
			ON rg.object_id = pt.object_id
			AND rg.pdw_node_id = pt.pdw_node_id
			AND pt.distribution_id = rg.distribution_id
		  JOIN sys.pdw_table_mappings tm
			ON pt.name = tm.physical_name
		  INNER JOIN sys.tables t
			ON tm.object_id = t.object_id
		  INNER JOIN sys.schemas s
			ON t.schema_id = s.schema_id
		  LEFT JOIN 
			 (
			 SELECT tm.object_id , ps.index_id,  
				SUM( case when ps.distribution_id = 1 then 1 else 0 end ) `par_count`, sum(ps.row_count) cmp_row_count,
				COUNT(distinct ps.distribution_id ) distributions
			   FROM sys.dm_pdw_nodes_db_partition_stats ps
					  join sys.pdw_nodes_tables nt on nt.object_id=ps.object_id and ps.distribution_id=nt.distribution_id
					  join sys.pdw_table_mappings tm on tm.physical_name=nt.name
			 --  WHERE ps.index_id<2
			   GROUP BY tm.object_id, ps.index_id--, ps.distribution_id
			 )  p on p.object_id = t.object_id
		WHERE   s.name =V_SchemaName

		--s.name NOT IN ('DWH_staging','DWH_Migration')
		--AND s.name LIKE 'DWH%'
		--AND t.name ='Fact_UserPageViews'
		--AND rg.partition_number = 222
		GROUP BY s.name, t.name, rg.partition_number,`par_count`
		HAVING 
		SUM(CASE WHEN rg.State = 1 THEN rg.Total_rows Else 0 END)>100000
		OR SUM(rg.deleted_rows)> 100000

	) t



     LIMIT 1);
EXECUTE IMMEDIATE V_sql

;
INSERT INTO dwh_daily_process.migration_tables.ColumnstoreRebuildLog
(SchemaName,Command,RebuildDate)
VALUES (V_SchemaName,V_sql,V_date)

;
SELECT V_sql

;
END;
