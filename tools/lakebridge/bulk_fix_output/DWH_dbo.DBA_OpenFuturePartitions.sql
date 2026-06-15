USE CATALOG dwh_daily_process;
USE SCHEMA migration_tables;



CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.DBA_OpenFuturePartitions(
IN V_Sname STRING,
IN V_Tname STRING,
IN V_FuturePeriodMonths tinyint)
LANGUAGE SQL
SQL SECURITY INVOKER
MODIFIES SQL DATA
AS

BEGIN

DECLARE V_PFunction string
;
DECLARE V_PS string
;
DECLARE V_FGName string 
;
DECLARE V_LastPartValue STRING -- we assume int for most,other types will error
;
DECLARE V_TargetDate date 
;
DECLARE V_RunnigDate date
;
DECLARE V_CountPartitions int 
;
DECLARE V_SqlStr STRING
;
select distinct V_PFunction= pf.name ,V_PS = ps.name
 
 from sys.indexes i
 
 join sys.partition_schemes ps on ps.data_space_id = i.data_space_id
 
 join sys.partition_functions pf on pf.function_id = ps.function_id 

where i.object_id = object_id(V_Sname || '.'||  V_Tname)

;

SELECT V_FGName = fg.name FROM sys.partitions
 p INNER JOIN sys.allocation_units au ON au.container_id = p.hobt_id 
 INNER JOIN sys.filegroups fg ON fg.data_space_id = au.data_space_id 
 WHERE p.object_id = OBJECT_ID(V_Sname || '.'||  V_Tname);

--select @PFunction
SET V_LastPartValue = (
SELECT
cast(MAX(value) as STRING) from sys.partition_functions PF
join sys.partition_range_values PRV
on PF.function_id = PRV.function_id
where PF.name = V_PFunction
group by PRV.function_id

--select @LastPartValue
 LIMIT 1);
Set V_TargetDate = LAST_DAY(DATEADD(MONTH, V_FuturePeriodMonths, CAST(V_LastPartValue as date)))
;
Set V_CountPartitions = DATEDIFF(CAST(V_LastPartValue as date), V_TargetDate);

--select @TargetDate,@CountPartitions
Set V_RunnigDate = CAST(V_LastPartValue as date)
;
WHILE V_CountPartitions >= 1  
DO
Set V_RunnigDate = DATEADD(DAY, 1, V_RunnigDate)
     ;
set V_SqlStr = ' ';
	 --print @SqlStr
EXECUTE IMMEDIATE V_SqlStr;
	
	 set V_CountPartitions -=1 
;
END WHILE;

--truncate table Fact_CustomerAction
END;
