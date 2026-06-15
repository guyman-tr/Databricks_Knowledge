USE CATALOG dwh_daily_process;
USE SCHEMA migration_tables;



CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.SP_KillTableauSessions(
)
LANGUAGE SQL
SQL SECURITY INVOKER
MODIFIES SQL DATA
AS

BEGIN

DECLARE V_StartJob TIMESTAMP
;
DECLARE V_killTableau  STRING;
DECLARE V_kill STRING
	
;

DECLARE V_kill2 STRING
	
;

DECLARE V_killdbForge  STRING;
SET V_StartJob=current_timestamp();
 
 	-- Log the start of the procedure in [DE_dbo].[Job_LogTable]
 	INSERT INTO dwh_daily_process.migration_tables.Job_LogTable 
( ActionDescription, Occurred)
 	VALUES ( 'Start Procedure:SP_KillTableauSessions', V_StartJob );
------------------------------------


SET V_killTableau = (
SELECT
ARRAY_JOIN(COLLECT_LIST(concat('kill "', session_id,'"')), ';') FROM 
	(SELECT session_id FROM dbo.ActiveQueriesMonitor
	 WHERE app_name LIKE '%Tableau%' AND 
	       login_name LIKE '%@etoro.com%' AND 
		   total_elapsed_time>=600000 AND
		   login_name NOT IN ('%alexsh@etoro.com%' )

	)a

 LIMIT 1);
	 INSERT INTO dwh_daily_process.migration_tables.TimeoutTerminator 
(WhenIKilled,login_name,SessionID,RequestID,Command,Start_Time,Duration_min)
	 SELECT current_timestamp(),login_name,session_id,request_id,command,start_time,duration_min   FROM dbo.ActiveQueriesMonitor 
	 WHERE app_name LIKE '%Tableau%' AND login_name LIKE '%@etoro.com%' AND total_elapsed_time>=600000;

	--AND app_name = 'dbForge SQL Complete'
	--- The app list was changed By Boris P (Pini's request)
SELECT V_killTableau
	;
EXECUTE IMMEDIATE V_killTableau
;

	SELECT COALESCE(V_killTableau, 'No killed Tableau sessions') killed_sessions;
	---------------------------------------
DROP VIEW IF EXISTS TEMP_TABLE_lck;
-- CREATE OR REPLACE TEMPORARY VIEW #lck with ROUND_ROBIN distribution

CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_lck
		 
		AS
		SELECT current_timestamp() collection_date,* FROM `dbo`.`BlockedSessionsNew`
		WHERE ( 
		`blocking_app_name` LIKE '%Tableau%'
		OR 
		`blocking_app_name` LIKE '%Microsoft SQL Server Management Studio%'
		--OR 
		--[blocking_app_name] is null 
		)
		OR
		(
		 (
		    (
		     blocking_login LIKE '%@etoro.com%'   
		  OR
		     blocking_client_id LIKE '%172.28.130.%' 
			) 
		  --  AND  DATEDIFF(MINUTE,[blocking_start_time],getdate())>10
		 ) --if blocking is more 10 minutes
         
		)

	;
SET V_kill = (
SELECT
ARRAY_JOIN(COLLECT_LIST(CONCAT('kill "', blocking_session_id,'"')), ';') FROM TEMP_TABLE_lck
	 LIMIT 1);
EXECUTE IMMEDIATE V_kill

;
	INSERT INTO `dbo`.`KilledTableauSessions`
	(`collection_date`, `blocked_session_id`, `blocked_request_id`, `blocked_command`, `blocked_login`, `blocked_app_name`, `blocked_client_id`, `blocked_start_time`, 
	`blocked_end_time`, 
	`blocking_session_id`, `blocking_request_id`, `blocking_command`, `blocking_login`, `blocking_app_name`, `blocking_client_id`, `blocking_start_time`, `blocking_end_time`)
	SELECT 
	`collection_date`, `blocked_session_id`, `blocked_request_id`, `blocked_command`, `blocked_login`, `blocked_app_name`, `blocked_client_id`, `blocked_start_time`, 
	`blocked_end_time`, `blocking_session_id`, `blocking_request_id`, `blocking_command`, `blocking_login`, `blocking_app_name`, `blocking_client_id`, 
	`blocking_start_time`, `blocking_end_time`
	FROM TEMP_TABLE_lck

	;
DROP VIEW IF EXISTS TEMP_TABLE_Killed_Tableau_Sessions;
-- CREATE OR REPLACE TEMPORARY VIEW #Killed_Tableau_Sessions with ROUND_ROBIN distribution

CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_Killed_Tableau_Sessions
	 AS
	SELECT *,current_timestamp() collection_time 
	FROM sys.dm_pdw_exec_sessions
	WHERE is_transactional=1
	AND app_name like 'Tableau%'
	AND status = 'Idle'

	;
SET V_kill2 = (
SELECT
ARRAY_JOIN(COLLECT_LIST(CONCAT('kill "', session_id,'"')), ';') FROM TEMP_TABLE_Killed_Tableau_Sessions
	 LIMIT 1);
EXECUTE IMMEDIATE V_kill2

;
	INSERT INTO `dbo`.KilledTableauSessions_transactional
	(`session_id`, `status`, `request_id`, `security_id`, `login_name`, `login_time`, `query_count`, 
	`is_transactional`, `client_id`, `app_name`, `sql_spid`, `collection_time`)
	SELECT
	`session_id`, `status`, `request_id`, `security_id`, `login_name`, `login_time`, `query_count`, 
	`is_transactional`, `client_id`, `app_name`, `sql_spid`, `collection_time` 
	FROM TEMP_TABLE_Killed_Tableau_Sessions
;

	SELECT COALESCE(CONCAT(V_kill,V_kill2), 'No blocking sessions') killed_sessions
	;

SET V_killdbForge = (
SELECT
ARRAY_JOIN(COLLECT_LIST(concat('kill "', session_id,'"')), ';') FROM 
	(SELECT session_id FROM sys.dm_pdw_exec_sessions
	WHERE status ='Idle' AND 
	 login_time<DATEADD(HOUR, -6, current_timestamp()) AND
	(app_name in( 'dbForge SQL Complete' ,'Tableau 2023.3','Tableau 2024.2','Tableau 2021.4'
	,'Microsoft SQL Server Management Studio','Microsoft SQL Server Management Studio - Query',
	'Microsoft SQL Server' )
	OR
    login_name LIKE '%@etoro.com%'
	))a
	--AND app_name = 'dbForge SQL Complete'
	--- The app list was changed By Boris P (Pini's request)
 LIMIT 1);
EXECUTE IMMEDIATE V_killdbForge
;

	SELECT COALESCE(V_killdbForge, 'No killed dbForge sessions') killed_sessions;
	-- Log the end of the procedure in [DE_dbo].[Job_LogTable]
SET V_StartJob=current_timestamp() ;
	INSERT INTO dwh_daily_process.migration_tables.Job_LogTable 
( ActionDescription, Occurred)
	VALUES ( 'End Procedure:SP_KillTableauSessions', V_StartJob );
-- [cleanup] drop session-scoped temp objects so the SP leaves no residue
DROP VIEW IF EXISTS TEMP_TABLE_Killed_Tableau_Sessions;
DROP VIEW IF EXISTS TEMP_TABLE_lck;
END;
