USE CATALOG dwh_daily_process;
USE SCHEMA migration_tables;



CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.SP_DWH_Status(
)
LANGUAGE SQL
SQL SECURITY INVOKER
MODIFIES SQL DATA
AS
  
BEGIN

DECLARE V_CycleFlag   INT  
;
DECLARE V_SourceFlag  INT;
--DECLARE @CubeFlag   AS INT  
DECLARE V_BidbFlag    INT  
;
DECLARE V_Issues      INT  
;
DECLARE V_DataIssues  INT  
;
DECLARE V_CurrDT_INT  INT  
;
DECLARE V_CurrDT  date  
;
DECLARE V_YestrDT_INT  INT  
;
DECLARE V_YestrDT  date  
;
DECLARE V_Run  INT  
;
SET V_CycleFlag  = 0  
;
SET V_SourceFlag = 0;
--SET @CubeFlag   = 0  
SET V_BidbFlag   = 0  
;
SET V_Issues     = 0  
;
SET V_CurrDT  = cast(current_timestamp() as date)  
;
SET V_YestrDT = cast(DATEADD(day, -1, current_timestamp()) as date)  
;
SET V_CurrDT_INT = cast(date_format(current_timestamp(), 'yyyyMMdd') as int)  
;
SET V_YestrDT_INT= cast(date_format(DATEADD(day, -1, current_timestamp()), 'yyyyMMdd') as int);
  


  --------

  
  -------
 /*Checing that DWH get to Daily Status*/
SET V_Run = (
SELECT
count(*) FROM   
 dwh_daily_process.migration_tables.Log_Main_Full  
WHERE   
 StartOccurred >= V_CurrDT   
  
/*Checking Cycles*/
 LIMIT 1);
SET V_CycleFlag = (
SELECT
case when   
 (  
 SUM(AbsCycle) - sum(abs(InProcessCOCycle)) > 500  and sum(case when abs(AbsCycle) <> 0.00 then 1 else 0 end ) > 20  
 )  
 OR  
 (  
-- sum(case when abs(InProcessCOCycle) <> 0.00 then 1 else 0 end ) > 15 and sum(abs(InProcessCOCycle)) > 500 --changed by Adi Ferber on 10.42018 to the row below  
    sum(case when abs(InProcessCOCycle) > 0.03 then 1 else 0 end ) > 15 and sum(abs(InProcessCOCycle)) > 500    
 )  
 --OR  
 --(  
 --sum(abs(InProcessCOCycle)) > 1000  
 --)  
   
  then 1 else 0 end FROM   
 dwh_daily_process.migration_tables.Util_ResultsLiabilities_Cycle  
WHERE   
 DateID = V_YestrDT_INT  
  
/*Checking Source to Target*/
 LIMIT 1);
SET V_SourceFlag = (
SELECT
case when count(*) > 0 then 1 else 0 end FROM   
 dwh_daily_process.migration_tables.Util_ResultsSourceToTarget_Actions  
WHERE   
 DateID = V_YestrDT_INT  
 and  
 Alert = 1  
 and (  
 (abs((TargetAmount - SourcetAmount ) / (SourcetAmount +1)) > 0.002 and Category<>'PositionClose')   
 or   
 (abs((TargetNumOfActions - SourceNumOfActions ) / (SourceNumOfActions + 1)) > 0.002)  
 or   
 (abs((TargetCommissionOnOpen - SourceCommissionOnOpen ) / (SourceCommissionOnOpen +1)) > 0.001)  
 or   
 (abs((TargetCommissionOnClose - SourceCommissionOnClose ) / (SourceCommissionOnClose+1) ) > 0.001)  
 )  
 --And Category <> 'Regulation 4 Customers' -- added  by adi ferber as it is on AMS SP  
/*Checking Cube Partition executions - we have 7 partitions*/  
----SELECT  
---- @CubeFlag = case when count(*) >= 7 then 0 else 1 end  
----FROM   
---- [OLAP].[DWH_dbo].[OLAP_Partitions]  
----WHERE   
---- cast(LastProcessed as date) = @CurrDT  
  
  
  
/*Summary of checklist*/
 LIMIT 1);
SET V_DataIssues = (
SELECT
V_CycleFlag+V_SourceFlag  LIMIT 1);
SET V_Issues = (
SELECT
V_CycleFlag+V_SourceFlag---+@CubeFlag    LIMIT 1);
IF V_DataIssues  = 0 and V_Run > 0   
THEN
 DELETE FROM dwh_daily_process.migration_tables.DWH_Status  
 WHERE CAST(UpdateDate as DATE) = cast(current_timestamp() as DATE) and `DWH_Status` = 2  
  

 INSERT INTO dwh_daily_process.migration_tables.DWH_Status  
        (`DWH_Status`  
        ,`Comments`  
        ,`UpdateDate`)  
    VALUES  
  (  
  2,  
  'DWH Data sucessfuly updated with yesterday information',  
  current_timestamp()  
  )  

ELSE


 DELETE FROM dwh_daily_process.migration_tables.DWH_Status    
 WHERE CAST(UpdateDate as DATE) = cast(current_timestamp() as DATE) and `DWH_Status` = 2  
   

 INSERT INTO dwh_daily_process.migration_tables.DWH_Status  
        (`DWH_Status`  
        ,`Comments`  
        ,`UpdateDate`)  
    VALUES  
  (  
  0,  
     'DWH Data update failed. Issues found in updateing process. ' || 'Cycle Issues: '|| CASE WHEN V_CycleFlag = 1 THEN 'Yes' ELSE 'No' END || ', Source to Target Issues: '||CASE WHEN @SourceFlag = 1 THEN 'Yes' ELSE 'No' END,  
     current_timestamp()  
  )  
 
END IF  
  
END 
IF V_Issues  = 0  
 THEN
 DELETE FROM dwh_daily_process.migration_tables.DWH_Status    
 WHERE CAST(UpdateDate as DATE) = cast(current_timestamp() as DATE) and `DWH_Status` in (0,1)  
  

 INSERT INTO dwh_daily_process.migration_tables.DWH_Status  
        (`DWH_Status`  
        ,`Comments`  
        ,`UpdateDate`)  
    VALUES  
  (  
  1,  
  'DWH sucessfuly updated with yesterday information',  
  current_timestamp()  
  )  
 
ELSE


 DELETE FROM dwh_daily_process.migration_tables.DWH_Status    
 WHERE CAST(UpdateDate as DATE) = cast(current_timestamp() as DATE) and `DWH_Status` in (0,1)  
   

 INSERT INTO dwh_daily_process.migration_tables.DWH_Status  
        (`DWH_Status`  
   ,`Comments`  
        ,`UpdateDate`)  
    VALUES  
  (  
  0,  
     'DWH update failed. Issues found in updateing process:' || CASE WHEN V_CycleFlag = 1 THEN 'Yes' ELSE 'No' END || ', Source to Target Issues: '||CASE WHEN @SourceFlag = 1 THEN 'Yes' ELSE 'No' END , --+', Cube Processing Issues: '+ CASE WHEN @CubeFlag = 1 THEN 'Yes' ELSE 'No' END ,  
     --'DWH update failed. Issues found in updateing process. ' + 'Cycle Issues: '+ CASE WHEN @CycleFlag = 1 THEN 'Yes' ELSE 'No' END + ', Source to Target Issues: '+CASE WHEN @SourceFlag = 1 THEN 'Yes' ELSE 'No' END , --+', Cube Processing Issues: '+ CASE WHEN @CubeFlag = 1 THEN 'Yes' ELSE 'No' END ,       
  current_timestamp()  
  )  

END IF
