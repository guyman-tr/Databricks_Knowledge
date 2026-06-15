USE CATALOG dwh_daily_process;
USE SCHEMA migration_tables;



CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.AddPartitionsToDWH(
IN V_date TIMESTAMP)
LANGUAGE SQL
SQL SECURITY INVOKER
MODIFIES SQL DATA
AS

BEGIN

DECLARE V_TableName string;

DECLARE V_SchemaName string;

DECLARE V_i int ;

DECLARE V_max int 
;

DROP VIEW IF EXISTS TEMP_TABLE_PAR_TABLES_LIST;

	CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_PAR_TABLES_LIST AS
SELECT sch.name schema_name, tbl.name table_name ,
	CAST ( CAST( max(cast(rng.value as int )) AS STRING) AS DATE) LastPar ,
	ROW_NUMBER() OVER (ORDER BY tbl.name) RN 
	
	FROM        sys.schemas    sch
	INNER JOIN  sys.tables     tbl ON  sch.schema_id   = tbl.schema_id
	INNER JOIN  sys.partitions prt ON  prt.`object_id` = tbl.`object_id`
	INNER JOIN  sys.indexes    idx ON  prt.`object_id` = idx.`object_id`               
								   AND prt.`index_id`  = idx.`index_id`
	INNER JOIN  sys.data_spaces ds ON  idx.`data_space_id` = ds.`data_space_id`
	INNER JOIN  sys.partition_schemes    ps  ON  ds.`data_space_id`  = ps.`data_space_id`
	INNER JOIN sys.partition_functions   pf  ON  ps.`function_id`    = pf.`function_id`
	LEFT JOIN sys.partition_range_values rng ON  pf.`function_id`    = rng.`function_id`
	AND  rng.`boundary_id` = prt.`partition_number`
	WHERE sch.name like 'DWH%'
	AND (tbl.name NOT LIKE '%`_`SWITCH' AND tbl.name NOT LIKE '%`_`SWITCH`_`SINGLE')
	GROUP BY sch.name, tbl.name 
	HAVING  
	CAST ( CAST( max(cast(rng.value as int )) AS STRING) AS DATE)< V_date
	 
	 ;
SET V_i = 1;

SET V_max = (
SELECT
max(RN) FROM TEMP_TABLE_PAR_TABLES_LIST
	

     LIMIT 1);
WHILE V_i<=V_max 
	DO

SET V_SchemaName = (
SELECT
`schema_name` FROM TEMP_TABLE_PAR_TABLES_LIST WHERE RN = V_i 

		 LIMIT 1);
SET V_TableName = (
SELECT
table_name FROM TEMP_TABLE_PAR_TABLES_LIST WHERE RN = V_i 

		 LIMIT 1);
call dwh_daily_process.migration_tables.AddPartitionsToTable(V_SchemaName , V_TableName, V_date);
SET V_i = V_i+1
	;
END WHILE ;


	-- select 1 n 
-- [cleanup] drop session-scoped temp objects so the SP leaves no residue
DROP VIEW IF EXISTS TEMP_TABLE_PAR_TABLES_LIST;
END;
