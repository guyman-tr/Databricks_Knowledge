USE CATALOG dwh_daily_process;
USE SCHEMA migration_tables;



CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.SP_Fact_FirstCustomerAction_DL_To_Synapse(
IN V_dt TIMESTAMP)
LANGUAGE SQL
SQL SECURITY INVOKER
MODIFIES SQL DATA
AS

BEGIN

DECLARE V_Yesterday  TIMESTAMP
;
DECLARE V_CurrentDate  TIMESTAMP
;
SET V_Yesterday = CAST(V_dt as TIMESTAMP);
SET V_CurrentDate = DATEADD(DAY, 1, V_Yesterday);
-- Select Parameter Run Ind - Fact_FirstCustomerAction -------------
	-- SELECT
	--[IndRun],
	--[IndRunRollToToday]
	--FROM [DWH_dbo].[DataSolutionsTablesRunInd](nolock)
	--WHERE [TableName] = 'Fact_FirstCustomerAction'
--------------------------------------------------------------------
-- Delete Rows - Fact_FirstCustomerAction --------------------------

	DELETE FROM dwh_daily_process.migration_tables.Fact_FirstCustomerAction
	WHERE FirstOccurred >= V_Yesterday;
--------------------------------------------------------------------
-- SP_Fact_FirstCustomerAction -------------------------------------
call dwh_daily_process.migration_tables.SP_Fact_FirstCustomerAction(V_Yesterday);
END;
