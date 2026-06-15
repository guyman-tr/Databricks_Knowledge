USE CATALOG dwh_daily_process;
USE SCHEMA migration_tables;



CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.SP_ProcessStatusLog(
IN V_Date TIMESTAMP,
IN V_ErrorDescription STRING,
IN V_TaskName STRING,
IN V_PackageName STRING,
IN V_TaskStatus STRING,
IN V_TableName STRING)
LANGUAGE SQL
SQL SECURITY INVOKER
MODIFIES SQL DATA
AS

BEGIN

DECLARE V_DateID  int
;
set V_DateID=CAST(date_format(V_Date, 'yyyyMMdd') AS int);

BEGIN

IF V_TaskStatus = 'Start'
				THEN
				INSERT INTO dwh_daily_process.migration_tables.DataSolutionsProcessesStatus
(
							`DateID`
							,`PackageName`
							,`TableName`
							,`TaskName`
							,`TaskStatus`
							,`TaskStart`)
				SELECT
						V_DateID,
						V_PackageName,
						V_TableName,
						V_TaskName,
						V_TaskStatus,
						current_timestamp()
				;
END IF;

	ELSEIF V_TaskStatus = 'Finish'
		
				THEN
				MERGE INTO dwh_daily_process.migration_tables.DataSolutionsProcessesStatus A_TGT USING ( SELECT DateID , TaskName , TaskStart FROM dwh_daily_process.migration_tables.DataSolutionsProcessesStatus WHERE TaskName = V_TaskName and DateID = V_DateID order by TaskStart desc ) a
ON dwh_daily_process.migration_tables.DataSolutionsProcessesStatus.TaskName = a.TaskName and dwh_daily_process.migration_tables.DataSolutionsProcessesStatus.DateID = a.DateID and dwh_daily_process.migration_tables.DataSolutionsProcessesStatus.TaskStart = a.TaskStart
WHEN MATCHED THEN UPDATE SET
TaskFinish = current_timestamp() ,
TaskStatus = V_TaskStatus;
END IF;

	ELSEIF V_TaskStatus = 'Failed'
		
				THEN
				INSERT INTO dwh_daily_process.migration_tables.DataSolutionsProcessesStatus
(
							`DateID`
							,`PackageName`
							,`TableName`
							,`TaskName`
							,`TaskStatus`
							,`ErrorDescription`
							,`TaskStart`
							
							)
				SELECT
						V_DateID,
						V_PackageName,
						V_TableName ,
						V_TaskName,
						V_TaskStatus,
						V_ErrorDescription,
						current_timestamp()

						
				;
END IF;

	
END;
