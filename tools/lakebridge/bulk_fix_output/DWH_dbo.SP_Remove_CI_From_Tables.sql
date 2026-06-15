USE CATALOG dwh_daily_process;
USE SCHEMA migration_tables;



CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.SP_Remove_CI_From_Tables(
IN V_schemaName STRING,
IN V_tableName STRING)
LANGUAGE SQL
SQL SECURITY INVOKER
MODIFIES SQL DATA
AS

BEGIN

 
DECLARE V_table  STRING ;

DECLARE V_sql  STRING
;
-- =============================================
-- Author:      <Re'em Cohen>
-- Create Date: <2021-09-30>
-- Description: Generic SP intended for checking whether CI are existing and if so removes it.
-- exec [DWH_dbo].[SP_Remove_CI_From_Tables]
-- =============================================

SET V_table = V_schemaName || '.' || V_tableName
;
IF EXISTS ( THEN
SELECT Name FROM sys.indexes 
	WHERE object_id = object_id(V_table) 
	AND  type_desc ='CLUSTERED'
	)

	THEN
SET V_sql =  (SELECT 'DROP INDEX ' || NAME || ' ON ' || V_table
		FROM sys.indexes 
		WHERE object_id = object_id(V_table)
		AND type_desc = 'CLUSTERED');
END IF;
SELECT V_sql

		;
EXECUTE IMMEDIATE V_sql

	 ;
END IF; 
END;
