USE CATALOG dwh_daily_process;
USE SCHEMA migration_tables;



CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.SP_STS_User_Operations_Data_History_CREATE_SWITCH_SINGLE(
IN V_dt TIMESTAMP)
LANGUAGE SQL
SQL SECURITY INVOKER
MODIFIES SQL DATA
AS

BEGIN

DECLARE V_sql STRING 
;
DECLARE V_sql2 STRING 
;
DECLARE V_range STRING 
;

DROP TABLE IF EXISTS dwh_daily_process.migration_tables.STS_User_Operations_Data_History_SWITCH_SINGLE

;
DROP TABLE IF EXISTS dwh_daily_process.migration_tables.STS_User_Operations_Data_History_SWITCH

		

;

SET V_range = (
SELECT
date_format(DATEADD(DAY, -1, V_dt), 'yyyyMMdd')  ||','|| date_format(V_dt, 'yyyyMMdd') ||','|| date_format(DATEADD(DAY, 1, V_dt), 'yyyyMMdd')  LIMIT 1);
SET V_sql = 'CREATE OR REPLACE TABLE dwh_daily_process.migration_tables.STS_User_Operations_Data_History_SWITCH_SINGLE
                 AS SELECT * FROM dwh_daily_process.migration_tables.STS_User_Operations_Data_History'
   ;
EXECUTE IMMEDIATE V_sql


   	;
SET V_sql2 = 'CREATE OR REPLACE TABLE dwh_daily_process.migration_tables.STS_User_Operations_Data_History_SWITCH
                 AS SELECT * FROM dwh_daily_process.migration_tables.STS_User_Operations_Data_History'
   ;
EXECUTE IMMEDIATE V_sql2

;
END;
