USE CATALOG dwh_daily_process;
USE SCHEMA migration_tables;



CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.SP_Fact_CustomerAction_CheckExistPartition(
IN V_dt TIMESTAMP)
LANGUAGE SQL
SQL SECURITY INVOKER
MODIFIES SQL DATA
AS

BEGIN



DECLARE V_dateID INT ;
/********************************************************************************************
Author:      Boris Slutski
Date:        2018-02-08
Description: Update table Fact_CustomerAction
 
**************************
** Change History
**************************
Date             Author       Description   
----------     ----------   ------------------------------------

*********************************************************************************************/
	--SET DEADLOCK_PRIORITY HIGH
	--exec [SP_Fact_CustomerAction_CheckExistPartition] '20200809'
    ---declare @dt datetime = cast(getdate()-1 as date)

SET V_dateID = CAST(date_format(V_dt, 'yyyyMMdd') AS int)
;

	select  Count(*) as IndExistPartition_Fact_CustomerAction
	from sys.partitions p
	inner join sys.indexes i 
	 on p.object_id = i.object_id 
	 and p.index_id = i.index_id
	inner JOIN sys.data_spaces ds 
	 on i.data_space_id = ds.data_space_id
	inner JOIN sys.partition_schemes ps 
	 on ds.data_space_id = ps.data_space_id
	left outer JOIN sys.partition_range_values prv 
	 on prv.function_id = ps.function_id 
	 and p.partition_number = prv.boundary_id
	where p.index_id = 1 
    AND p.`object_id` = NULL
	and prv.value = CAST(date_format(V_dt, 'yyyyMMdd') AS int);

--	SET DEADLOCK_PRIORITY NORMAL


END;
