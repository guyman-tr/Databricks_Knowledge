USE CATALOG dwh_daily_process;
USE SCHEMA migration_tables;



CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.SP_Test_Liabilities_Cycle(
IN V_date TIMESTAMP,
IN V_numberofdays int)
LANGUAGE SQL
SQL SECURITY INVOKER
MODIFIES SQL DATA
AS
 
BEGIN



DECLARE V_dateid  int
;
DECLARE V_yesterdaydate  TIMESTAMP
;
DECLARE V_yesterdaydateid  int;
--declare @numberofdays int
--set @numberofdays=1
--set @date='2014-03-10'
/********************************************************************************************
Author:      Boris Slutski
Date:        2018-02-08
Description: Update table Util_ResultsLiabilities_Cycle - Check Data
 
**************************
** Change History
**************************
Date             Author       Description   
----------     ----------   ------------------------------------
 
*********************************************************************************************/

--declare @date as datetime

set V_dateid=CAST(date_format(V_date, 'yyyyMMdd') AS int)
;
set V_yesterdaydate=(select DATEADD(day, -1*V_numberofdays, V_date))
;
set V_yesterdaydateid=CAST(date_format(V_yesterdaydate, 'yyyyMMdd') AS int)


;
delete from  dwh_daily_process.migration_tables.Util_ResultsLiabilities_Cycle where DateID=V_dateid

;
insert into dwh_daily_process.migration_tables.Util_ResultsLiabilities_Cycle
(DateID
										,CID
										,Regulation
										,PlayerStatusName
										,CloseBalance
										,MIMO_Amount
										,UnrealizedChange
										,BonusChange
										,OpenBalance
										,Cycle
										,AbsCycle
										,CalcCloseBalace
										,InProcessCOCycle
										,UpdateDate)

select V_dateid
,a.CID
,rr.Name as Regulation
,ps.Name
,a.Liabilities as CloseBalance
,COALESCE(b.Amount, 0) as Amount
,(COALESCE(a.PositionPnL, 0)-COALESCE(c.PositionPnL, 0)) as UnrealizedChange
,(COALESCE(a.ActualNWA, 0)-COALESCE(c.ActualNWA, 0)) as BonusChange
,COALESCE(c.Liabilities, 0) as OpenBalance
,(a.Liabilities-COALESCE(b.Amount, 0)-(COALESCE(a.PositionPnL, 0)-COALESCE(c.PositionPnL, 0))+(COALESCE(a.ActualNWA, 0)-COALESCE(c.ActualNWA, 0))-COALESCE(c.Liabilities, 0)) as Cycle
,abs(a.Liabilities-COALESCE(b.Amount, 0)-(COALESCE(a.PositionPnL, 0)-COALESCE(c.PositionPnL, 0))+(COALESCE(a.ActualNWA, 0)-COALESCE(c.ActualNWA, 0))-COALESCE(c.Liabilities, 0)) as AbsCycle
,COALESCE(b.Amount, 0)+(COALESCE(a.PositionPnL, 0)-COALESCE(c.PositionPnL, 0))-(COALESCE(a.ActualNWA, 0)-COALESCE(c.ActualNWA, 0))+COALESCE(c.Liabilities, 0) as CalcCloseBalace
,COALESCE(a.InProcessCashouts, 0) - (COALESCE(c.InProcessCashouts, 0)+ COALESCE(COMovements, 0)) as InProcessCOCycle
, current_timestamp()

from dwh_daily_process.migration_tables.Val_FCV_ClosingBalance a
LEFT JOIN dwh_daily_process.migration_tables.Val_FCV_MovementSum b
	on a.CID=b.RealCID
LEFT JOIN dwh_daily_process.migration_tables.Val_FCV_OpeningBalance c
	on a.CID=c.CID
LEFT JOIN dwh_daily_process.migration_tables.Val_FCV_COMovements co 
	on co.RealCID = a.CID
LEFT JOIN dwh_daily_process.migration_tables.Dim_Customer cc
    on a.CID = cc.RealCID
LEFT JOIN dwh_daily_process.migration_tables.Dim_Regulation rr
	on cc.RegulationID = rr.DWHRegulationID
LEFT JOIN dwh_daily_process.migration_tables.Dim_PlayerStatus ps
	on cc.PlayerStatusID = ps.PlayerStatusID;

--select CID,Regulation,OpenBalance,MIMO_Amount,UnrealizedChange as UnrealizedPNLChange,CloseBalance,CalcCloseBalace,Cycle as Gap,AbsCycle as AbsGap,InProcessCOCycle
--from [DWH_dbo].Util_ResultsLiabilities_Cycle
--where DateID=@dateid and abs(Cycle)>1


END;
