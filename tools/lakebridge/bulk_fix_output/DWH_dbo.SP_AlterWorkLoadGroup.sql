USE CATALOG dwh_daily_process;
USE SCHEMA migration_tables;



CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.SP_AlterWorkLoadGroup(
IN V_group_name STRING,
IN V_min_percentage_resource int,
IN V_cap_percentage_resource int,
IN V_request_min_resource_grant_percent int,
IN V_request_max_resource_grant_percent int,
IN V_importance STRING,
IN V_query_execution_timeout_sec int)
LANGUAGE SQL
SQL SECURITY INVOKER
MODIFIES SQL DATA
AS

BEGIN


SET V_alter = (
SELECT
CONCAT(
'ALTER WORKLOAD GROUP `',
V_group_name,
'` WITH (', 
CASE WHEN @min_percentage_resource IS NOT NULL THEN 'MIN_PERCENTAGE_RESOURCE = ' END,
V_min_percentage_resource  ,
CASE WHEN @cap_percentage_resource IS NOT NULL THEN ' ,CAP_PERCENTAGE_RESOURCE = ' END ,
V_cap_percentage_resource,
CASE WHEN @request_min_resource_grant_percent IS NOT NULL THEN ' ,REQUEST_MIN_RESOURCE_GRANT_PERCENT = ' END,
V_request_min_resource_grant_percent,
CASE WHEN @request_max_resource_grant_percent IS NOT NULL THEN ' ,REQUEST_MAX_RESOURCE_GRANT_PERCENT = ' END,
V_request_max_resource_grant_percent,
CASE WHEN @importance IS NOT NULL THEN ' ,IMPORTANCE =' END,
V_importance,
CASE WHEN @query_execution_timeout_sec IS NOT NULL THEN ' ,QUERY_EXECUTION_TIMEOUT_SEC =' END,
V_query_execution_timeout_sec,
' )'
)  LIMIT 1);
EXECUTE IMMEDIATE V_alter
      --PRINT @alter
END;
