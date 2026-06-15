USE CATALOG dwh_daily_process;
USE SCHEMA migration_tables;



CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.CopyIntoTable_ByDate(
IN V_schemaname STRING,
IN V_tablename STRING,
IN V_filetype STRING,
IN V_mainfolder STRING,
IN V_date TIMESTAMP)
LANGUAGE SQL
SQL SECURITY INVOKER
MODIFIES SQL DATA
AS


BEGIN

DECLARE --@date date = '2021-07-01',
V_identity STRING ;

DECLARE V_secret STRING ;

DECLARE V_sql STRING ;

DECLARE V__secret STRING;

DECLARE V_chardate STRING;

DECLARE V_path STRING
;
SET --@date date = '2021-07-01', = 'Managed Identity';
SET V_secret = 'sp=rl&st=2021-07-01T11:26:43Z&se=2024-07-04T19:26:43Z&spr=https&sv=2020-02-10&sr=c&sig=Ly9UbQyC6RuGmrsdlybNIaOUVMmCGmij00xZDiWbVL4%3D';
SET V_sql = '';
SET V__secret = '';

SET V_chardate = (
SELECT
CONVERT( STRING,V_date,23)  LIMIT 1);
SET V_path = (
SELECT
'' || V_mainfolder||'/etr_y='||LEFT(V_chardate,4)||'/etr_ym='||LEFT(V_chardate,7)||'/etr_ymd='||V_chardate||'/*.parquet'
--print @path  LIMIT 1);
SET V__secret = (
SELECT
CASE 
                    WHEN V_identity ='Managed Identity' THEN ')'
					ELSE ', SECRET="'||V_secret||'")' END  LIMIT 1)
SET V_sql ='TRUNCATE TABLE '||V_schemaname||'.' || V_tablename 


SELECT V_sql

EXECUTE IMMEDIATE V_sql          


SET V_sql ='COPY INTO '||V_schemaname||'.'||V_tablename||' 
FROM "'||V_path||'"
WITH (
    FILE_TYPE = "'||V_filetype||'",
    CREDENTIAL=(IDENTITY= "'||V_identity||'"'||V__secret||')'



SELECT V_sql

EXECUTE IMMEDIATE V_sql 


END
