USE CATALOG dwh_daily_process;
USE SCHEMA migration_tables;



CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.SP_Dim_Instrument_Correlation_ByGroupRange(
IN V_Date TIMESTAMP,
IN V_TableID int,
IN V_MinGroupID int,
IN V_MaxGroupID int)
LANGUAGE SQL
SQL SECURITY INVOKER
MODIFIES SQL DATA
AS

BEGIN

 	   
DECLARE V_ErrorMessage STRING ;

DECLARE V_ErrorSeverity INT ;

DECLARE V_ErrorState INT ;

-- [stub] EXIT HANDLER block elided (Databricks lets exceptions bubble)
-- Run the first call with IsInitial = 1

call dwh_daily_process.migration_tables.SP_Dim_Instrument_Correlation_FilterByInstrumentID(V_Date, V_MinGroupID, V_TableID, 1);
--Need Delete
        -- Increment group ID for the loop

SET V_MinGroupID = V_MinGroupID + 1;
-- Loop through remaining group IDs with IsInitial = 0

WHILE V_MinGroupID <= V_MaxGroupID
        DO
call dwh_daily_process.migration_tables.SP_Dim_Instrument_Correlation_FilterByInstrumentID(V_Date, V_MinGroupID, V_TableID, 0);
--Not Need Delete

SET V_MinGroupID = V_MinGroupID + 1;

END WHILE;
END;
