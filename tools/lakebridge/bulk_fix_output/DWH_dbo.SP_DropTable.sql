USE CATALOG dwh_daily_process;
USE SCHEMA migration_tables;



CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.SP_DropTable(
IN V_SchemaName STRING,
IN V_TableName STRING)
LANGUAGE SQL
SQL SECURITY INVOKER
MODIFIES SQL DATA
AS

BEGIN


DECLARE V_sql STRING
;
-- =============================================
-- Author:      <Re'em Cohen>
-- Create Date: 2022-03-23
-- Description: Genric SP intended to drop tables
-- exec [DWH_dbo].[SP_DropTable] <schemaName> ,<tableName>
-- =============================================

SET V_sql = 
	(SELECT 
		'IF OBJECT_ID("'||V_SchemaName||'.'||V_TableName||'")
		IS NOT NULL DROP TABLE '||V_SchemaName||'.'||V_TableName
	);
	
--print @sql
EXECUTE IMMEDIATE V_sql

;
END;
