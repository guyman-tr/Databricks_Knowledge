USE CATALOG dwh_daily_process;
USE SCHEMA migration_tables;



CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.SP_Fact_CustomerAction_Create_SWITCH_SINGLE(
IN V_dt TIMESTAMP)
LANGUAGE SQL
SQL SECURITY INVOKER
MODIFIES SQL DATA
AS

BEGIN



DECLARE V_sql STRING 
;
DECLARE V_sql2 STRING 
;
DECLARE V_range STRING 
;
--------DECLARE @Identity_Max BIGINT
--------SET @Identity_Max = (select MAX(CustomerActionID) from dbo.Fact_CustomerAction) + 1

--------DECLARE @Statement VARCHAR(MAX)

DROP TABLE IF EXISTS dwh_daily_process.migration_tables.Fact_CustomerAction_SWITCH_SINGLE

		

;

SET V_range = (
SELECT
date_format(DATEADD(DAY, -1, V_dt), 'yyyyMMdd')  ||','|| date_format(V_dt, 'yyyyMMdd') ||','|| date_format(DATEADD(DAY, 1, V_dt), 'yyyyMMdd')
--       SELECT @range = STRING_AGG(cast(rng.value as varchar(max)),',') WITHIN GROUP (ORDER BY CAST(rng.value as int))
--	FROM        sys.schemas    sch
--	INNER JOIN  sys.tables     tbl ON  sch.schema_id   = tbl.schema_id
--	INNER JOIN  sys.partitions prt ON  prt.[object_id] = tbl.[object_id]
--	INNER JOIN  sys.indexes    idx ON  prt.[object_id] = idx.[object_id] AND prt.[index_id]  = idx.[index_id]
--	INNER JOIN  sys.data_spaces ds ON  idx.[data_space_id] = ds.[data_space_id]
--	INNER JOIN  sys.partition_schemes  ps  ON  ds.[data_space_id]  = ps.[data_space_id]
--	INNER JOIN  sys.partition_functions pf  ON  ps.[function_id]    = pf.[function_id]
--	LEFT  JOIN  sys.partition_range_values rng ON  pf.[function_id]    = rng.[function_id]
--	AND  rng.[boundary_id] = prt.[partition_number]
--	WHERE tbl.object_id =NULL
--	and idx.index_id = 1
--	and rng.value  is not null 
----	ORDER BY CAST(rng.value as int)  LIMIT 1);
SET V_sql = 'CREATE OR REPLACE TABLE dwh_daily_process.migration_tables.Fact_CustomerAction_SWITCH_SINGLE
                 AS SELECT * FROM dwh_daily_process.migration_tables.Fact_CustomerAction'
   
EXECUTE IMMEDIATE V_sql




		
DROP TABLE IF EXISTS dwh_daily_process.migration_tables.Fact_CustomerAction_SWITCH

	
SET V_sql2 = 'CREATE OR REPLACE TABLE dwh_daily_process.migration_tables.Fact_CustomerAction_SWITCH
                 AS SELECT * FROM dwh_daily_process.migration_tables.Fact_CustomerAction'
   
EXECUTE IMMEDIATE V_sql2


   

END
