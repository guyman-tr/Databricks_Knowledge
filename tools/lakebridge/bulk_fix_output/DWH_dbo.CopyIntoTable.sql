USE CATALOG dwh_daily_process;
USE SCHEMA migration_tables;



CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.CopyIntoTable(
IN V_schemaname STRING,
IN V_tablename STRING,
IN V_path STRING,
IN V_filetype STRING)
LANGUAGE SQL
SQL SECURITY INVOKER
MODIFIES SQL DATA
AS


BEGIN

DECLARE V_identity STRING ;

DECLARE V_secret STRING ;

DECLARE V_sql STRING ;

DECLARE V__secret STRING;

SET V_identity = 'Managed Identity';
SET V_secret = 'sp=rl&st=2021-07-01T11:26:43Z&se=2024-07-04T19:26:43Z&spr=https&sv=2020-02-10&sr=c&sig=Ly9UbQyC6RuGmrsdlybNIaOUVMmCGmij00xZDiWbVL4%3D';
SET V_sql = '';
SET V__secret = ''
;

SET V__secret = (
SELECT
CASE 
                    WHEN V_identity ='Managed Identity' THEN ')'
					ELSE ', SECRET="'||V_secret||'")' END  LIMIT 1);
SET V_sql =';
TRUNCATE TABLE ' || V_schemaname || '.' || V_tablename || '

COPY INTO '||V_schemaname||'.'||V_tablename||' 
FROM "'||V_path||'";
WITH (
    FILE_TYPE = "'||V_filetype||'",
    CREDENTIAL=(IDENTITY= "'||V_identity||'"'||V__secret||')'

;
EXECUTE IMMEDIATE V_sql 

;
END;
