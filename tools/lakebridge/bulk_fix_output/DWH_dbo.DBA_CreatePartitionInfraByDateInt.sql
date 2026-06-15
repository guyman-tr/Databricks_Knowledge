USE CATALOG dwh_daily_process;
USE SCHEMA migration_tables;



CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.DBA_CreatePartitionInfraByDateInt(
IN V_main_Start_date TIMESTAMP,
IN V_secondary_length int)
LANGUAGE SQL
SQL SECURITY INVOKER
MODIFIES SQL DATA
AS

BEGIN

DECLARE V_pfnameprefix STRING ;

DECLARE V_psnameprefix STRING ;

DECLARE V_filegroup STRING ;

DECLARE V_SqlStr STRING ;

DECLARE V_SecondLoopCount int 
;
DECLARE V_MainLoopCount int
;
DECLARE V_StartDateSecond date 
;
DECLARE V_EndDateMain date 
;
DECLARE V_EndDateSecond date
;
DECLARE V_RunningDate date
;
DECLARE V_CntMain int ;

DECLARE V_CntSecond int ;

SET V_pfnameprefix = 'PF_USERPAGESVIEWS'
;
SET V_psnameprefix = 'PS_USERPAGESVIEWS'
;
SET V_filegroup = 'DataFG1'
;
SET V_SqlStr = ''
;
SET V_CntMain = 0 
;
SET V_CntSecond = 1 ;
--Past by Month
--Set @MainLoopCount =  DATEDIFF(MM,@main_Start_date ,cast(getdate()as date)) 
--Set @EndDateMain = DATEADD(MM,@MainLoopCount - @secondary_length + 1 ,@main_Start_date )

--Past by Day

Set V_MainLoopCount =  DATEDIFF(V_main_Start_date, cast(current_timestamp()as date)) 
;
set V_EndDateMain = DATEADD(DAY, V_MainLoopCount - V_secondary_length + 1, V_main_Start_date)


;
Set V_StartDateSecond = V_EndDateMain;
--Past by Month
--set @EndDateSecond = EOMONTH(DATEADD(MM, @MainLoopCount  ,@main_Start_date))  --  Partition past by month 
--Past by Day
set V_EndDateSecond = DATEADD(DAY, V_MainLoopCount, V_main_Start_date)  --  Partition past by day 
;
set V_SecondLoopCount = DATEDIFF(V_StartDateSecond, V_EndDateSecond);

--select @MainLoopCount,@main_Start_date,@EndDateMain,@EndDateSecond
SET V_SqlStr = 'CREATE PARTITION FUNCTION ' ||  V_pfnameprefix || '_MONTH_DAYS (int) '
|| ' AS RANGE LEFT FOR VALUES ( '

;
WHILE V_CntMain < V_MainLoopCount
DO
--Past by Month
    --set @SqlStr = @SqlStr + CAST( cast(format(DATEADD(MM,@CntMain ,@main_Start_date) ,'yyyyMMdd') as int)as varchar)  +  ',' 
	--Past by Day

set V_SqlStr = V_SqlStr + CAST( cast(date_format(DATEADD(DAY, V_CntMain, V_main_Start_date), 'yyyyMMdd') as int)as STRING)  ||  ',';
	set V_CntMain +=1 
;
END WHILE;
WHILE V_CntSecond <= V_SecondLoopCount
DO
--set @SqlStr = @SqlStr + CAST( cast(format(DATEADD(DD,@CntSecond ,@EndDateMain) ,'yyyyMMdd') as int)as varchar) + IIF ( @CntSecond <= @SecondLoopCount-1 , ',', '' )  

set V_SqlStr = V_SqlStr + CAST( cast(date_format(DATEADD(DAY, V_CntSecond, V_EndDateMain), 'yyyyMMdd') as int)as STRING)
 ;
IF  V_CntSecond <= V_SecondLoopCount-1  
 THEN
set V_SqlStr = V_SqlStr ||   ','
 ;
END WHILE IF;
	set V_CntSecond +=1 
;

set V_SqlStr = V_SqlStr || '); ' || char(13)  +Char(10) || ';


set V_SqlStr += ' CREATE PARTITION SCHEME ' || V_psnameprefix || '_MONTH_DAYS 
AS PARTITION ' || +  V_pfnameprefix || '_MONTH_DAYS  
ALL TO ( ' ||  V_filegroup || ');'  


;
SELECT V_SqlStr

;
END;
