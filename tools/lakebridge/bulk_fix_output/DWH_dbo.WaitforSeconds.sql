USE CATALOG dwh_daily_process;
USE SCHEMA migration_tables;



CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.WaitforSeconds(
IN V_seconds int)
LANGUAGE SQL
SQL SECURITY INVOKER
MODIFIES SQL DATA
AS

BEGIN

DECLARE V_date TIMESTAMP;

DECLARE V_val int
;
SET V_date=current_timestamp()
;
WHILE DATEDIFF(SECOND, current_timestamp(), V_date) < V_seconds
DO
set V_val =V_val
;
END WHILE;
END;
