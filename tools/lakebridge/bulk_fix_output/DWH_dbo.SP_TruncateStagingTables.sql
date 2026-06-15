USE CATALOG dwh_daily_process;
USE SCHEMA migration_tables;



CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.SP_TruncateStagingTables(
IN V_tableName STRING)
LANGUAGE SQL
SQL SECURITY INVOKER
MODIFIES SQL DATA
AS

BEGIN

DECLARE V_schemaName  STRING ;

DECLARE V_sql STRING
;
SET V_schemaName = 'DWH_staging'
;
SET V_sql = 
	(SELECT 
		'IF OBJECT_ID("'||V_schemaName||'.'||V_tableName||'")
		IS NOT NULL TRUNCATE TABLE '||V_schemaName||'.'||V_tableName
	);
	
	--print @sql
EXECUTE IMMEDIATE V_sql
	
;
END;
