USE CATALOG dwh_daily_process;
USE SCHEMA migration_tables;



CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.SP_STS_User_Operations_Data_History_SWITCH(
)
LANGUAGE SQL
SQL SECURITY INVOKER
MODIFIES SQL DATA
AS

BEGIN




DECLARE V_CurrentDay int
;
DECLARE V_PartToSwitch int 
;
DECLARE V_SqlStr STRING
;
DECLARE V_TS BOOLEAN ;

DECLARE V_MaxValue int
;
DECLARE V_MinValue int
;
DECLARE V_LastPar int
;
DECLARE V_IsRight BOOLEAN 
;
DECLARE V_MaxValue_SGL int
;
DECLARE V_MinValue_SGL int
;
DECLARE V_LastPar_SGL int
;
DECLARE V_IsRight_SGL BOOLEAN 
;
DECLARE V_PartToSwitch_SGL int;
-----------------------
--   set deadlock_priority high
--- we have to have same indexes and constraints as partitioned table

SET V_TS = 1
;
set  V_CurrentDay = (SELECT DateID from dwh_daily_process.migration_tables.STS_User_Operations_Data_History_SWITCH_SINGLE);

-----create constraint for table
--set @SqlStr = 'ALTER TABLE STS_User_Operations_Data_History_SWITCH_SINGLE ADD CONSTRAINT FCASS_value_for_switch CHECK (DateID = ' || CAST(@CurrentDay as varchar) || ' );'

----print @SqlStr
--exec (@SqlStr)

-------------------------------------------
-- get the partition number for the dateid 

--select @PartToSwitch = $partition.PF_CUSTOMERACTION_MONTH_DAYS(@CurrentDay)
SET V_MaxValue_SGL = (
SELECT
max(cast(rng.value as int )) FROM        sys.schemas    sch
INNER JOIN  sys.tables     tbl ON  sch.schema_id   = tbl.schema_id
INNER JOIN  sys.partitions prt ON  prt.`object_id` = tbl.`object_id`
INNER JOIN  sys.indexes    idx ON  prt.`object_id` = idx.`object_id`               AND                                prt.`index_id`  = idx.`index_id`
INNER JOIN  sys.data_spaces ds ON  idx.`data_space_id` = ds.`data_space_id`
INNER JOIN  sys.partition_schemes    ps  ON  ds.`data_space_id`  = ps.`data_space_id`
INNER JOIN sys.partition_functions   pf  ON  ps.`function_id`    = pf.`function_id`
LEFT JOIN sys.partition_range_values rng ON  pf.`function_id`    = rng.`function_id`
AND  rng.`boundary_id` = prt.`partition_number`
WHERE tbl.object_id =NULL


 LIMIT 1);
SET V_MinValue_SGL = (
SELECT
min(cast(rng.value as int )) FROM        sys.schemas    sch
INNER JOIN  sys.tables     tbl ON  sch.schema_id   = tbl.schema_id
INNER JOIN  sys.partitions prt ON  prt.`object_id` = tbl.`object_id`
INNER JOIN  sys.indexes    idx ON  prt.`object_id` = idx.`object_id`               AND                                prt.`index_id`  = idx.`index_id`
INNER JOIN  sys.data_spaces ds ON  idx.`data_space_id` = ds.`data_space_id`
INNER JOIN  sys.partition_schemes    ps  ON  ds.`data_space_id`  = ps.`data_space_id`
INNER JOIN sys.partition_functions   pf  ON  ps.`function_id`    = pf.`function_id`
LEFT JOIN sys.partition_range_values rng ON  pf.`function_id`    = rng.`function_id`
AND  rng.`boundary_id` = prt.`partition_number`
WHERE tbl.object_id =NULL


 LIMIT 1);
SET V_IsRight_SGL = (
SELECT
max(cast(pf.boundary_value_on_right as int)) FROM        sys.schemas    sch
INNER JOIN  sys.tables     tbl ON  sch.schema_id   = tbl.schema_id
INNER JOIN  sys.partitions prt ON  prt.`object_id` = tbl.`object_id`
INNER JOIN  sys.indexes    idx ON  prt.`object_id` = idx.`object_id`               AND                                prt.`index_id`  = idx.`index_id`
INNER JOIN  sys.data_spaces ds ON  idx.`data_space_id` = ds.`data_space_id`
INNER JOIN  sys.partition_schemes    ps  ON  ds.`data_space_id`  = ps.`data_space_id`
INNER JOIN sys.partition_functions   pf  ON  ps.`function_id`    = pf.`function_id`
LEFT JOIN sys.partition_range_values rng ON  pf.`function_id`    = rng.`function_id`
AND  rng.`boundary_id` = prt.`partition_number`
WHERE tbl.object_id =NULL


 LIMIT 1);
SET V_LastPar_SGL = (
SELECT
max(partition_number) FROM        sys.schemas    sch
INNER JOIN  sys.tables     tbl ON  sch.schema_id   = tbl.schema_id
INNER JOIN  sys.partitions prt ON  prt.`object_id` = tbl.`object_id`
INNER JOIN  sys.indexes    idx ON  prt.`object_id` = idx.`object_id`               AND                                prt.`index_id`  = idx.`index_id`
INNER JOIN  sys.data_spaces ds ON  idx.`data_space_id` = ds.`data_space_id`
INNER JOIN  sys.partition_schemes    ps  ON  ds.`data_space_id`  = ps.`data_space_id`
INNER JOIN sys.partition_functions   pf  ON  ps.`function_id`    = pf.`function_id`
LEFT JOIN sys.partition_range_values rng ON  pf.`function_id`    = rng.`function_id`
AND  rng.`boundary_id` = prt.`partition_number`
WHERE tbl.object_id =NULL


 LIMIT 1);
SET V_MaxValue = (
SELECT
max(cast(rng.value as int )) FROM        sys.schemas    sch
INNER JOIN  sys.tables     tbl ON  sch.schema_id   = tbl.schema_id
INNER JOIN  sys.partitions prt ON  prt.`object_id` = tbl.`object_id`
INNER JOIN  sys.indexes    idx ON  prt.`object_id` = idx.`object_id`               AND                                prt.`index_id`  = idx.`index_id`
INNER JOIN  sys.data_spaces ds ON  idx.`data_space_id` = ds.`data_space_id`
INNER JOIN  sys.partition_schemes    ps  ON  ds.`data_space_id`  = ps.`data_space_id`
INNER JOIN sys.partition_functions   pf  ON  ps.`function_id`    = pf.`function_id`
LEFT JOIN sys.partition_range_values rng ON  pf.`function_id`    = rng.`function_id`
AND  rng.`boundary_id` = prt.`partition_number`
WHERE tbl.object_id =NULL





         LIMIT 1);
SET V_MinValue = (
SELECT
min(cast(rng.value as int )) FROM        sys.schemas    sch
INNER JOIN  sys.tables     tbl ON  sch.schema_id   = tbl.schema_id
INNER JOIN  sys.partitions prt ON  prt.`object_id` = tbl.`object_id`
INNER JOIN  sys.indexes    idx ON  prt.`object_id` = idx.`object_id`               AND                                prt.`index_id`  = idx.`index_id`
INNER JOIN  sys.data_spaces ds ON  idx.`data_space_id` = ds.`data_space_id`
INNER JOIN  sys.partition_schemes    ps  ON  ds.`data_space_id`  = ps.`data_space_id`
INNER JOIN sys.partition_functions   pf  ON  ps.`function_id`    = pf.`function_id`
LEFT JOIN sys.partition_range_values rng ON  pf.`function_id`    = rng.`function_id`
AND  rng.`boundary_id` = prt.`partition_number`
WHERE tbl.object_id =NULL





         LIMIT 1);
SET V_IsRight = (
SELECT
max(cast(pf.boundary_value_on_right as int)) FROM        sys.schemas    sch
INNER JOIN  sys.tables     tbl ON  sch.schema_id   = tbl.schema_id
INNER JOIN  sys.partitions prt ON  prt.`object_id` = tbl.`object_id`
INNER JOIN  sys.indexes    idx ON  prt.`object_id` = idx.`object_id`               AND                                prt.`index_id`  = idx.`index_id`
INNER JOIN  sys.data_spaces ds ON  idx.`data_space_id` = ds.`data_space_id`
INNER JOIN  sys.partition_schemes    ps  ON  ds.`data_space_id`  = ps.`data_space_id`
INNER JOIN sys.partition_functions   pf  ON  ps.`function_id`    = pf.`function_id`
LEFT JOIN sys.partition_range_values rng ON  pf.`function_id`    = rng.`function_id`
AND  rng.`boundary_id` = prt.`partition_number`
WHERE tbl.object_id =NULL





         LIMIT 1);
SET V_LastPar = (
SELECT
max(partition_number) FROM        sys.schemas    sch
INNER JOIN  sys.tables     tbl ON  sch.schema_id   = tbl.schema_id
INNER JOIN  sys.partitions prt ON  prt.`object_id` = tbl.`object_id`
INNER JOIN  sys.indexes    idx ON  prt.`object_id` = idx.`object_id`               AND                                prt.`index_id`  = idx.`index_id`
INNER JOIN  sys.data_spaces ds ON  idx.`data_space_id` = ds.`data_space_id`
INNER JOIN  sys.partition_schemes    ps  ON  ds.`data_space_id`  = ps.`data_space_id`
INNER JOIN sys.partition_functions   pf  ON  ps.`function_id`    = pf.`function_id`
LEFT JOIN sys.partition_range_values rng ON  pf.`function_id`    = rng.`function_id`
AND  rng.`boundary_id` = prt.`partition_number`
WHERE tbl.object_id =NULL





         LIMIT 1);
IF V_CurrentDay <= V_MinValue_SGL 
		THEN
SET V_PartToSwitch_SGL = 1 
		;
END IF;
IF V_CurrentDay > V_MaxValue_SGL 
		THEN
SET V_PartToSwitch_SGL=V_LastPar_SGL
		;
END IF;
IF V_PartToSwitch_SGL IS NULL 
		 THEN

			SELECT V_PartToSwitch_SGL = prt.`partition_number` FROM        sys.schemas    sch
			INNER JOIN  sys.tables     tbl ON  sch.schema_id   = tbl.schema_id
			INNER JOIN  sys.partitions prt ON  prt.`object_id` = tbl.`object_id`
			INNER JOIN  sys.indexes    idx ON  prt.`object_id` = idx.`object_id` AND prt.`index_id`  = idx.`index_id`
			INNER JOIN  sys.data_spaces ds ON  idx.`data_space_id` = ds.`data_space_id`
			INNER JOIN  sys.partition_schemes  ps  ON  ds.`data_space_id`  = ps.`data_space_id`
			INNER JOIN  sys.partition_functions pf  ON  ps.`function_id`    = pf.`function_id`
			LEFT  JOIN  sys.partition_range_values rng ON  pf.`function_id`    = rng.`function_id`
			AND  rng.`boundary_id` = prt.`partition_number`
			WHERE tbl.object_id =NULL
			AND rng.value  >= V_CurrentDay
			ORDER BY CAST(rng.value as int)
		;
END IF;
IF V_CurrentDay <= V_MinValue 
		THEN
SET V_PartToSwitch = 1 
		;
END IF;
IF V_CurrentDay > V_MaxValue 
		THEN
SET V_PartToSwitch=V_LastPar
		;
END IF;
IF V_PartToSwitch IS NULL 
		 THEN

			SELECT V_PartToSwitch = prt.`partition_number` FROM        sys.schemas    sch
			INNER JOIN  sys.tables     tbl ON  sch.schema_id   = tbl.schema_id
			INNER JOIN  sys.partitions prt ON  prt.`object_id` = tbl.`object_id`
			INNER JOIN  sys.indexes    idx ON  prt.`object_id` = idx.`object_id` AND prt.`index_id`  = idx.`index_id`
			INNER JOIN  sys.data_spaces ds ON  idx.`data_space_id` = ds.`data_space_id`
			INNER JOIN  sys.partition_schemes  ps  ON  ds.`data_space_id`  = ps.`data_space_id`
			INNER JOIN  sys.partition_functions pf  ON  ps.`function_id`    = pf.`function_id`
			LEFT  JOIN  sys.partition_range_values rng ON  pf.`function_id`    = rng.`function_id`
			AND  rng.`boundary_id` = prt.`partition_number`
			WHERE tbl.object_id =NULL
			AND rng.value  >= V_CurrentDay
			ORDER BY CAST(rng.value as int)
		;
END IF; 



---------------------------------------------------------------------------
-- build switch statement

--- 1 .switch existing data in partition to shadow table 
Set V_SqlStr = 'ALTER TABLE dwh_daily_process.migration_tables.STS_User_Operations_Data_History SWITCH PARTITION ' || CAST(V_PartToSwitch as STRING) ||
' TO dwh_daily_process.migration_tables.STS_User_Operations_Data_History_SWITCH PARTITION ' || CAST(V_PartToSwitch_SGL as STRING) || ';';
--print @SqlStr   
EXECUTE IMMEDIATE V_SqlStr;

--- 2 .switch new data to partitioned table
Set V_SqlStr = 'ALTER TABLE dwh_daily_process.migration_tables.STS_User_Operations_Data_History_SWITCH_SINGLE SWITCH PARTITION ' || CAST(V_PartToSwitch_SGL as STRING) || '  TO dwh_daily_process.migration_tables.STS_User_Operations_Data_History PARTITION ' || CAST(V_PartToSwitch as STRING) ||' WITH (TRUNCATE_TARGET = ON);';
--print @SqlStr
EXECUTE IMMEDIATE V_SqlStr;
--- 3. remove check constraint
---Set @SqlStr = 'ALTER TABLE dbo.STS_User_Operations_Data_History_SWITCH_SINGLE DROP CONSTRAINT FCASS_value_for_switch'

-- print @SqlStr
---exec (@SqlStr)

--- 4 . truncate shadow table
TRUNCATE TABLE dwh_daily_process.migration_tables.STS_User_Operations_Data_History_SWITCH

;
END;
