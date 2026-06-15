USE CATALOG dwh_daily_process;
USE SCHEMA migration_tables;



CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.CheckIfPartitionExists(
IN V_SchemaName STRING,
IN V_TableName STRING,
IN V_Range STRING,
OUT V_IsPartitionExist BOOLEAN)
LANGUAGE SQL
SQL SECURITY INVOKER
MODIFIES SQL DATA
AS

BEGIN





DECLARE V_Pdate DATE 
;
DECLARE V_IsPartitionExist_Fact_CustomerAction BOOLEAN
;
DECLARE V_Date date ;

DECLARE V_DateID int ;
----Add Partitions----------------------------


SET V_Pdate = (
SELECT
LAST_DAY(DATEADD(month, 1, current_timestamp()))  LIMIT 1);
call dwh_daily_process.migration_tables.AddPartitionsTo_BI_DB( V_Pdate
);
call dwh_daily_process.migration_tables.AddPartitionsToDWH( V_Pdate

------------------------------------------------
);
SET V_Date = CAST(V_Range AS date)
;
SET V_DateID = cast(date_format(V_Date, 'yyyyMMdd') AS int)
--print @Date
--print @DateID
;
IF EXISTS (
			SELECT rng.value FROM        sys.schemas    sch
					INNER JOIN  sys.tables     tbl ON  sch.schema_id   = tbl.schema_id
					INNER JOIN  sys.partitions prt ON  prt.`object_id` = tbl.`object_id`
					INNER JOIN  sys.indexes    idx ON  prt.`object_id` = idx.`object_id`               
														AND  prt.`index_id`  = idx.`index_id`
					INNER JOIN  sys.data_spaces ds ON  idx.`data_space_id` = ds.`data_space_id`
					INNER JOIN  sys.partition_schemes    ps  ON  ds.`data_space_id`  = ps.`data_space_id`
					INNER JOIN sys.partition_functions   pf  ON  ps.`function_id`    = pf.`function_id`
					INNER JOIN sys.partition_range_values rng ON  pf.`function_id`    = rng.`function_id`
					AND  rng.`boundary_id` = prt.`partition_number`
					WHERE tbl.name  = V_TableName
					AND sch.name=V_SchemaName
					AND rng.value = V_DateID --@Range
			)
			THEN
SET V_IsPartitionExist = 1 
			;
ELSE


SET V_IsPartitionExist = 0
				;
END IF;

SELECT V_IsPartitionExist AS IsPartitionExist
;
END;
