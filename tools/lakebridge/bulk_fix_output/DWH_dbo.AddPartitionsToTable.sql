USE CATALOG dwh_daily_process;
USE SCHEMA migration_tables;



CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.AddPartitionsToTable(
IN V_SchemaName STRING,
IN V_TableName STRING,
IN V_ToDate TIMESTAMP)
LANGUAGE SQL
SQL SECURITY INVOKER
MODIFIES SQL DATA
AS

BEGIN

DECLARE V_FromDate    Date 
;
DECLARE V_i INT ;

DECLARE V_max INT 
;
DECLARE V_sql STRING ;

DROP VIEW IF EXISTS TEMP_TABLE_PAR_TABLES;
DROP VIEW IF EXISTS TEMP_TABLE_TBL ;
DROP VIEW IF EXISTS TEMP_TABLE_SPLIT_RANGE;
DROP VIEW IF EXISTS TEMP_TABLE_ERRORS;
CREATE OR REPLACE TABLE TEMP_TABLE_ERRORS (TableName STRING, `Range` STRING,  ErrorMessage STRING) USING DELTA
	;
CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_TBL (ddate date);
	

	SELECT  CONCAT( '`',sch.name,'`.`', tbl.name,'`') table_name ,
	CAST ( CAST( max(cast(rng.value as int )) AS STRING) AS DATE) LastPar 

	INTO TEMP_TABLE_PAR_TABLES 
	FROM        sys.schemas    sch
	INNER JOIN  sys.tables     tbl ON  sch.schema_id   = tbl.schema_id
	INNER JOIN  sys.partitions prt ON  prt.`object_id` = tbl.`object_id`
	INNER JOIN  sys.indexes    idx ON  prt.`object_id` = idx.`object_id`               
										AND  prt.`index_id`  = idx.`index_id`
	INNER JOIN  sys.data_spaces ds ON  idx.`data_space_id` = ds.`data_space_id`
	INNER JOIN  sys.partition_schemes    ps  ON  ds.`data_space_id`  = ps.`data_space_id`
	INNER JOIN sys.partition_functions   pf  ON  ps.`function_id`    = pf.`function_id`
	LEFT JOIN sys.partition_range_values rng ON  pf.`function_id`    = rng.`function_id`
	AND  rng.`boundary_id` = prt.`partition_number`
	WHERE tbl.name  = V_TableName
	AND sch.name=V_SchemaName

	group by sch.name, tbl.name 

;
SET V_FromDate = (
SELECT
MIN(LastPar ) FROM TEMP_TABLE_PAR_TABLES 
	 LIMIT 1);
WHILE V_FromDate < V_ToDate
	DO
SET V_FromDate = DATEADD(day, 1, V_FromDate);
		 INSERT INTO TEMP_TABLE_TBL
(ddate)
		 SELECT V_FromDate
	 
	;
END WHILE ;


	CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_SPLIT_RANGE AS
select 
	'BEGIN TRY  END TRY;
		BEGIN CATCH;
		  INSERT INTO TEMP_TABLE_ERRORS (TableName , `Range` , ErrorMessage ) 
		  SELECT "' || P.table_name ||  '" table_name ,'||date_format(T.ddate, 'yyyyMMdd') ||'RANGE,MESSAGE_TEXT AS ErrorMessage; END CATCH;' comm,
	ROW_NUMBER() OVER (ORDER BY P.table_name,T.ddate) ID 
	
	from TEMP_TABLE_TBL T
	JOIN TEMP_TABLE_PAR_TABLES P ON T.ddate > P.LastPar;
	--order by  P.table_name,T.ddate
SET V_i = 1 
;
SET V_sql = '';

SET V_max = (
SELECT
max(ID) FROM TEMP_TABLE_SPLIT_RANGE
	 LIMIT 1);
WHILE V_i<=V_max
	DO

SET V_sql = (
SELECT
comm FROM TEMP_TABLE_SPLIT_RANGE WHERE ID = V_i 
		 LIMIT 1);
EXECUTE IMMEDIATE V_sql;
		--PRINT @sql
SET V_i = V_i+1

	;
END WHILE ;


--	SELECT * FROM #ERRORS
END;
