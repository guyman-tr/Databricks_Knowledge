USE CATALOG dwh_daily_process;
USE SCHEMA migration_tables;



CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.SP_Log_Table_Updates(
IN V_DateID int,
IN V_TableName STRING,
IN V_TableStatus STRING,
IN V_Error STRING,
IN V_ProcessName STRING,
IN V_ProcessSource STRING,
IN V_StartTime TIMESTAMP,
IN V_EndTime TIMESTAMP)
LANGUAGE SQL
SQL SECURITY INVOKER
MODIFIES SQL DATA
AS

BEGIN

-- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    

    -- Insert statements for procedure here

    INSERT INTO dwh_daily_process.migration_tables.TablesUpdatesProcessesStatus VALUES 
(V_DateID, V_TableName, V_TableStatus, V_Error, V_ProcessName, V_ProcessSource, V_StartTime, V_EndTime)
;
END;
