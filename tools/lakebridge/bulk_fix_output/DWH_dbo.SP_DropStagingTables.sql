USE CATALOG dwh_daily_process;
USE SCHEMA migration_tables;



CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.SP_DropStagingTables(
IN V_tableName STRING)
LANGUAGE SQL
SQL SECURITY INVOKER
MODIFIES SQL DATA
AS

BEGIN


DECLARE V_schemaName  STRING ;

DECLARE V_sql STRING
;
-- =============================================
-- Author:      <Re'em Cohen>
-- Create Date: 2021-09-05
-- Description: SP intended to drop staging tables before DWH process
-- exec [DWH_dbo].[SP_DropStagingTables] <schemaName> ,<tableName>
-- =============================================

SET V_schemaName = 'DWH_staging'
;
SET V_sql = 
	(SELECT 
		'IF OBJECT_ID("'||V_schemaName||'.'||V_tableName||'")
		IS NOT NULL DROP TABLE '||V_schemaName||'.'||V_tableName
	);
	
--print @sql
EXECUTE IMMEDIATE V_sql

;
END;
