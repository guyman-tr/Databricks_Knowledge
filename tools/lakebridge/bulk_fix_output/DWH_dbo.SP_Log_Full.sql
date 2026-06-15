USE CATALOG dwh_daily_process;
USE SCHEMA migration_tables;



CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.SP_Log_Full(
IN V_process STRING,
IN V_subrocess STRING,
IN V_dateID int,
IN V_type tinyint,
IN V_rowcount int,
IN V_error int,
IN V_errormsg STRING,
IN V_partitionid int)
LANGUAGE SQL
SQL SECURITY INVOKER
MODIFIES SQL DATA
AS

BEGIN

/****************************************************/
	/* @type is a tinyint which holds if the procedure  */
	/* is activeated in the begining of the sub process */
	/* or in the end of it                              */
	/* 1- begin of process                              */
	/* 10- end of process                                */
	/****************************************************/

	----if @process = 'Fact_CustomerAction' and @subrocess = 'STG_Real_History_Credit_ForFactAction' and @type = 1
	----	delete from [DWH_dbo].Log_Main_Full where DateID = @dateID and Process = @process

IF V_error IS NULL 
		;
SET V_error=0
	;
IF V_errormsg IS NULL 
		;
SET V_errormsg=''
	;
IF V_partitionid IS NULL 
		;
SET V_partitionid=0

	;
IF V_type = 1;
		insert INTO dwh_daily_process.migration_tables.Log_Main_Full 
( DateID, Process, SubProcess, StartOccurred, `Type`, Row_Count, PartitionID )
		select V_dateID
		,      V_process
		,      V_subrocess
		,      current_timestamp()
		,      V_type
		,      V_rowcount
		,      V_partitionid
	else
		update dwh_daily_process.migration_tables.Log_Main_Full;
		set FinishOccurred = current_timestamp()
		,   `Type` =         V_type
		,   Row_Count =      V_rowcount
		,   Error =          V_error
		,   ErrorMsg =       V_errormsg
		where Process = V_process
			and SubProcess = V_subrocess
			and DateID = V_dateID
			and PartitionID = V_partitionid

	;
IF V_error>0;
	BEGIN

		insert INTO dwh_daily_process.migration_tables.Log_Main_Full 
( Process, SubProcess, DateID, `Type`, Row_Count, Error, ErrorMsg )
		select V_process
		,      V_subrocess
		,      V_dateID
		,      V_type
		,      V_rowcount
		,      V_error
		,      V_errormsg
	end/*internal if */
SELECT 'etl.FollowUp - @process :' || V_process || ' @subrocess : ' || V_subrocess || ' @type : ' || CAST(V_type AS STRING) || ' TIMESTAMP : ' || date_format(current_timestamp(), 'dd MMM yyyy hh:mm:ss:SSS')||'Row Count: '||CAST(V_rowcount AS STRING)
	 
END/*Porcedure*/
END;
