USE CATALOG dwh_daily_process;
USE SCHEMA migration_tables;



CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.DeleteFromParquetMetadata(
IN V_tablename STRING,
IN V_schemaname STRING)
LANGUAGE SQL
SQL SECURITY INVOKER
MODIFIES SQL DATA
AS

BEGIN



DELETE FROM dwh_daily_process.migration_tables.ParquetMetadata
 WHERE TableName =V_tablename and V_schemaname = SchemaName

;

END;
