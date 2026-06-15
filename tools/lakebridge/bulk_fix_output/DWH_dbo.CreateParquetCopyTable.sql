USE CATALOG dwh_daily_process;
USE SCHEMA migration_tables;



CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.CreateParquetCopyTable(
IN V_tablename STRING,
IN V_schemaname STRING)
LANGUAGE SQL
SQL SECURITY INVOKER
MODIFIES SQL DATA
AS

BEGIN

DECLARE V_sql STRING 
;
SET V_sql = (SELECT 
CONCAT ('IF OBJECT_ID("'||V_schemaname||'.'||V_tablename||'") IS NOT NULL DROP TABLE '||V_schemaname||'.'||V_tablename,
       ' CREATE OR REPLACE TABLE ',
	   V_schemaname||'.'||V_tablename, 
	   ' (',
		ARRAY_JOIN(COLLECT_LIST(CONCAT ( '`',ColumnName,'`' ,' ',CASE
WHEN DataType ='String'   THEN 'STRING' 
WHEN DataType ='Boolean'  THEN 'BOOLEAN' 
WHEN DataType ='TIMESTAMP' THEN 'timestamp' 
WHEN DataType ='Int64'    THEN 'bigint' 
WHEN DataType ='Int32'    THEN 'int' 
WHEN DataType ='Decimal'  THEN 'DECIMAL(38,6)' /*--'DECIMAL(19,4)' */
WHEN DataType ='Byte``'  THEN 'BINARY' 
WHEN DataType in ('Single','Double') THEN 'DOUBLE' END )), ' ,') WITHIN GROUP (ORDER BY Id ),
				') ;'
				)
	
  FROM dwh_daily_process.migration_tables.ParquetMetadata
  WHERE TableName =V_tablename and V_schemaname = SchemaName)
  --print @sql
;
EXECUTE IMMEDIATE V_sql










;
END
