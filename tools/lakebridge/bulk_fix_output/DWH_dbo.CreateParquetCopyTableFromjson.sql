USE CATALOG dwh_daily_process;
USE SCHEMA migration_tables;



CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.CreateParquetCopyTableFromjson(
IN V_tablename STRING,
IN V_schemaname STRING,
IN V_json STRING)
LANGUAGE SQL
SQL SECURITY INVOKER
MODIFIES SQL DATA
AS

BEGIN

DECLARE V_sql STRING ;
WITH CTE as (
 SELECT  j.`key`,
         v.`key` rtype, v.value 
 FROM OpenJson(V_json) j
 CROSS APPLY OpenJson(j.value) v
 );



SET V_sql = (SELECT 
CONCAT ('IF OBJECT_ID("'||V_schemaname||'.'||V_tablename||'") IS NOT NULL DROP TABLE '||V_schemaname||'.'||V_tablename,
       ' CREATE OR REPLACE TABLE ',
	   V_schemaname||'.'||V_tablename, 
	   ' (',
		ARRAY_JOIN(COLLECT_LIST(CONCAT ( '`',c1.value,'`' ,' ',
CASE
WHEN  c2.value  ='String'   THEN 'STRING' 
WHEN  c2.value  ='Boolean'  THEN 'BOOLEAN' 
WHEN  c2.value  ='TIMESTAMP' THEN 'timestamp' 
WHEN  c2.value  ='Int64'    THEN 'bigint' 
WHEN  c2.value  ='Int32'    THEN 'int' 
WHEN  c2.value  ='Decimal'  THEN 'DECIMAL(38,6)' /*--'DECIMAL(19,4)' */
WHEN  c2.value  ='Byte``'  THEN 'BINARY' 
WHEN  c2.value  in ('Single','Double') THEN 'DOUBLE' END )), ' ,') WITHIN GROUP (ORDER BY c1.`key` ),
				') ;'
				)
 
 
 from CTE c1
 join CTE c2 on c1.`key`=c2.`key` and c1.rtype='name' and c2.rtype='type'



   limit 1);
EXECUTE IMMEDIATE V_sql



;
END;
