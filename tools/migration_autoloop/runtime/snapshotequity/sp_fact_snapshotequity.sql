BEGIN



DECLARE V_daybefore   TIMESTAMP;
DECLARE V_auxdate   TIMESTAMP;
DECLARE V_largedate   TIMESTAMP;
DECLARE V_minCreditID  INT;
DECLARE V_maxCreditID  INT;
DECLARE V_maxentrydate   TIMESTAMP;
DECLARE V_dateid  INT;
DECLARE V_StartOfMonth TIMESTAMP;
DECLARE V_ProcessName   STRING;
DECLARE V_rowcount  INT ;

DECLARE V_maxupdatedate   TIMESTAMP;
--EXEC [DWH_dbo].[SP_Fact_SnapshotEquity] '20250908'
/********************************************************************************************
Author:      Boris Slutski
Date:        2018-03-11
Description: Update table Fact_SnapshotEquity
 
**************************
** Change History
**************************
Date             Author       Description   
----------     ----------   ------------------------------------
2019-03-03    Boris Slutski  Remove table [DWH_dbo].Ext_FSE_TotalStockOrders - withou data in PROD from 2015
2020-06-07    Boris Slutski  Change formula for Calcutaion TotalCash
2020-01-02    Boris Slutski  Cahnge Calculation of table #TotalCashPreviousDate
2022-01-27    Inbal BML      Add TRS fields
2024-10-30	  Daniel Kaplan	 Add futures fields :TotalMirrorRealFuturesPositionAmount,TotalRealFutures,TotalFuturesProviderMargin,TotalFuturesLockedCash	
2025-09-30    Daniel Kaplan  Add Stock Margin :TotalStocksMargin,TotalStockMarginLoanValue
*********************************************************************************************/


	--DECLARE @date AS DATETIME SET @date='20241209'

SET V_rowcount = 0;
SET V_daybefore = DATEADD(DAY, -1, V_date);
SET V_auxdate = DATEADD(DAY, 1, V_date);
SET V_largedate = (select cast(cast(year(V_date) as STRING)||'12'||'31' as TIMESTAMP));
SET V_maxentrydate = (SELECT CASE WHEN month(V_date)=01 and day(V_date)=01 THEN DATEADD(YEAR, -1, V_largedate) ELSE V_largedate END);
set V_dateid=CAST(date_format(DATEADD(day, DATEDIFF(0, V_date), 0), 'yyyyMMdd') AS int);
SET V_StartOfMonth = (
SELECT
DATEADD(day, 1-EXTRACT(day from V_auxdate), V_auxdate)  LIMIT 1);
--SET @ProcessName='Equity'

DROP TABLE IF EXISTS TEMP_TABLE_outputdata;
CREATE OR REPLACE TABLE TEMP_TABLE_outputdata (Action STRING NOT NULL,
	 CID int NOT NULL,
	 DateRangeID bigint NOT NULL) USING DELTA;
/**************************************************************PREPERE STG TABLE*********************************************************************/

DROP VIEW IF EXISTS TEMP_TABLE_TotalCashPreviousDate;
--select a.DateRangeID, a.CID, a.TotalCash as TotalCashPreviousDate 
--into #TotalCashPreviousDate
--from Fact_SnapshotEquity a
--where left(a.DateRangeID, 4) = year(@date)
--and right(a.DateRangeID, 4) = 1231;

CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_TotalCashPreviousDate AS
select a.DateRangeID, a.CID, a.TotalCash as TotalCashPreviousDate 

from dwh_daily_process.migration_tables.Fact_SnapshotEquity a
where left(a.DateRangeID, 4) = 
(
case 
when 
DATEADD(YEAR, CAST(DATEDIFF(0, V_date) / 365 AS INT), 0) = V_date -- if first day of year
then year(V_date)-1
else year(V_date)
end
)
and right(a.DateRangeID, 4) = 1231;
--create CLUSTERED index #TotalCashPreviousDate on #TotalCashPreviousDate(CID);

-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks)
TRUNCATE TABLE dwh_daily_process.migration_tables.Ext_FSE_Fact_SnapshotEquity;
	INSERT INTO dwh_daily_process.migration_tables.Ext_FSE_Fact_SnapshotEquity
(CID
										,CreditID						
										,TotalPositionsAmount
										,TotalMirrorPositionsAmount	
										,TotalStockPositionAmount
										,TotalMirrorStockPositionAmount	
										
										,TotalCryptoPositionAmount           -- added
										,TotalMirrorCryptoPositionAmount     -- added

										,TotalRealStocks           -- added
										,TotalRealCrypto     -- added
										,TotalRealCryptoLoan

										,TotalCash	
										,TotalCashCalculation
										,BonusCredit	
										,RealizedEquity	
										,Credit	
										,AUM		
										,TotalMirrorCash			
										,TotalStockOrders			
										,TotalMirrorStockOrders		
										,InProcessCashouts
										,TotalCryptoPositionAmount_TRS
										,TotalMirrorCryptoPositionAmount_TRS
										,Total_TRSCrypto
										------------------Futures------------------
									   ,TotalMirrorRealFuturesPositionAmount
									   ,TotalRealFutures
									   ,TotalFuturesProviderMargin
									   ,TotalFuturesLockedCash	
									   	--2025-09-29 Stock Margin
									   ,`TotalStocksMargin`
									   ,`TotalStockMarginLoanValue`
										)/*min(SpecialEquity,BonusCredit)*/
										
	SELECT hc.CID 
		 , hc.CreditID
		 , COALESCE(pa.TotalPositionAmount, 0) AS TotalPositionsAmount
		 , COALESCE(pa.TotalMirrorPositionAmount, 0) AS TotalMirrorPositionsAmount
		 , COALESCE(pa.TotalStockPositionAmount, 0) AS TotalStockPositionAmount
		 , COALESCE(pa.TotalMirrorStockPositionAmount, 0) AS TotalMirrorStockPositionAmount
		 
		 , COALESCE(pa.TotalCryptoPositionAmount, 0) AS TotalCryptoPositionAmount               --  added
		 , COALESCE(pa.TotalMirrorCryptoPositionAmount, 0) AS TotalMirrorCryptoPositionAmount   --  added

		 , COALESCE(pa.TotalRealStocks, 0) AS TotalRealStocks               --  added
		 , COALESCE(pa.TotalRealCrypto, 0) AS TotalRealCrypto   --  added
		 , COALESCE(pa.TotalRealCryptoLoan, 0) AS TotalRealCryptoLoan   --  added

		 -----, isnull(hc.TotalCash, 0) AS TotalCash    -- from 2020.06.07
		 , COALESCE(tcap.TotalCashPreviousDate, 0) + COALESCE(tca.TotalCashChangeAll, 0) as TotalCash
		 , COALESCE(tcap.TotalCashPreviousDate, 0) + COALESCE(tca.TotalCashChangeAll, 0) as TotalCashCalculation
		 , COALESCE(hc.BonusCredit, 0) as BonusCredit
		 , case when COALESCE(hc.RealizedEquity, 0)=0 then 
		  ---isnull(hc.TotalCash, 0)+isnull(pa.TotalPositionAmount, 0)+--isnull(so.TotalStockOrders, 0)+ -- from 2020.06.07
		  COALESCE(tcap.TotalCashPreviousDate, 0) + COALESCE(tca.TotalCashChangeAll, 0)+COALESCE(pa.TotalPositionAmount, 0)+--isnull(so.TotalStockOrders, 0)+
		  COALESCE(ic.InProcessCashouts, 0) 
		  else COALESCE(hc.RealizedEquity, 0) end  as RealizedEquity
		 , COALESCE(hc.Credit, 0) as Credit
		---- , isnull(pa.TotalMirrorPositionAmount,0)+isnull(hc.TotalCash,0)-isnull(hc.Credit, 0)--+isnull(so.TotalMirrorStockOrders, 0) -- from 2020.06.07
		 , COALESCE(pa.TotalMirrorPositionAmount, 0)+COALESCE(tcap.TotalCashPreviousDate, 0) + COALESCE(tca.TotalCashChangeAll, 0)-COALESCE(hc.Credit, 0)  AS AUM --+isnull(so.TotalMirrorStockOrders, 0)
		---, isnull(hc.TotalCash,0)-isnull(hc.Credit, 0) AS TotalMirrorCash -- from 2020.06.07
		 , COALESCE(tcap.TotalCashPreviousDate, 0) + COALESCE(tca.TotalCashChangeAll, 0)-COALESCE(hc.Credit, 0) AS TotalMirrorCash
		 , 0 AS TotalStockOrders
		 , 0 AS TotalMirrorStockOrders
		 , COALESCE(ic.InProcessCashouts, 0) AS InProcessCashouts
		 , COALESCE(pa.TotalCryptoPositionAmount_TRS, 0) AS TotalCryptoPositionAmount_TRS
		 , COALESCE(pa.TotalMirrorCryptoPositionAmount_TRS, 0) AS TotalMirrorCryptoPositionAmount_TRS
		 , COALESCE(pa.Total_TRSCrypto, 0) AS Total_TRSCrypto
		 ------------------Futures------------------
		 , COALESCE(pa.TotalMirrorRealFuturesPositionAmount, 0) as TotalMirrorRealFuturesPositionAmount
		 , COALESCE(pa.TotalRealFutures, 0) as TotalRealFutures
		 , COALESCE(pa.TotalFuturesProviderMargin, 0) as TotalFuturesProviderMargin
		 , COALESCE(pa.TotalFuturesLockedCash, 0) as TotalFuturesLockedCash
		 --2025-09-29 Stock Margin
		 , COALESCE(pa.`TotalStocksMargin`, 0) as `TotalStocksMargin`
		 , COALESCE(pa.`TotalStockMarginLoanValue`, 0) as `TotalStockMarginLoanValue`
	FROM dwh_daily_process.migration_tables.Ext_FSE_Real_History_Credit hc
		--left join [DWH_dbo].Ext_FSE_TotalStockOrders so
		--on(hc.CID=so.CID)
		left join dwh_daily_process.migration_tables.Ext_FSE_InProcessCashouts ic
		on(hc.CID=ic.CID)
		left join dwh_daily_process.migration_tables.Ext_FSE_TotalPositionAmount pa
		on(hc.CID=pa.CID)

		left join dwh_daily_process.migration_tables.Ext_FSE_TotalCashChangeAll tca
		on(hc.CID=tca.CID)
		left join TEMP_TABLE_TotalCashPreviousDate tcap
		on(hc.CID=tcap.CID);
---****  Treatmant for Position than change CAST(IsSettled AS INT) for column TotalRealStocks & TotalRealCrypto

DROP VIEW IF EXISTS TEMP_TABLE_Ext_FSE_PositionChangeLog_CID;

CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_Ext_FSE_PositionChangeLog_CID AS
select distinct CID 

from dwh_daily_process.migration_tables.Ext_FSE_PositionChangeLog;
--------------------
-- Update in CFD to Real 

insert into  TEMP_TABLE_Ext_FSE_PositionChangeLog_CID
select distinct CID 
from dwh_daily_process.migration_tables.Ext_FSE_TotalPositionAmount where CID not in ( select CID from TEMP_TABLE_Ext_FSE_PositionChangeLog_CID);
----------------------
--create clustered index #Ext_FSE_PositionChangeLog_CID on #Ext_FSE_PositionChangeLog_CID (CID);

INSERT INTO dwh_daily_process.migration_tables.Ext_FSE_Fact_SnapshotEquity
(CID
										,CreditID						
										,TotalPositionsAmount
										,TotalMirrorPositionsAmount	
										,TotalStockPositionAmount
										,TotalMirrorStockPositionAmount							
										,TotalCryptoPositionAmount           -- added
										,TotalMirrorCryptoPositionAmount     -- added
										,TotalRealStocks           -- added
										,TotalRealCrypto     -- added
										,TotalRealCryptoLoan
										,TotalCash					
										,BonusCredit	
										,RealizedEquity	
										,Credit	
										,AUM		
										,TotalMirrorCash			
										,TotalStockOrders			
										,TotalMirrorStockOrders		
										,InProcessCashouts
										,TotalCashCalculation
										,TotalCryptoPositionAmount_TRS
										,TotalMirrorCryptoPositionAmount_TRS
										,Total_TRSCrypto
										------------------Futures------------------
									   ,TotalMirrorRealFuturesPositionAmount
									   ,TotalRealFutures
									   ,TotalFuturesProviderMargin
									   ,TotalFuturesLockedCash	
									   --2025-09-29 Stock Margin
									   ,TotalStocksMargin	
									   ,TotalStockMarginLoanValue							   
										)
select 
a.CID
,a.CreditID						
,COALESCE(a.TotalPositionsAmount, 0)
,COALESCE(a.TotalMirrorPositionsAmount, 0)
,COALESCE(a.TotalStockPositionAmount, 0)
,COALESCE(a.TotalMirrorStockPositionAmount, 0)										
,COALESCE(a.TotalCryptoPositionAmount, 0)           
,COALESCE(a.TotalMirrorCryptoPositionAmount, 0)     
,COALESCE(pa.TotalRealStocks, 0)           
,COALESCE(pa.TotalRealCrypto, 0)    
,COALESCE(pa.TotalRealCryptoLoan, 0)      
,COALESCE(a.TotalCash, 0)					
,COALESCE(a.BonusCredit, 0)	
,COALESCE(a.RealizedEquity, 0)	
,COALESCE(a.Credit, 0)	
,COALESCE(a.AUM, 0)		
,COALESCE(a.TotalMirrorCash, 0)			
,COALESCE(a.TotalStockOrders, 0)			
,COALESCE(a.TotalMirrorStockOrders, 0)		
,COALESCE(a.InProcessCashouts, 0)
,COALESCE(a.TotalCashCalculation, 0)
,COALESCE(pa.TotalCryptoPositionAmount_TRS, 0)
,COALESCE(pa.TotalMirrorCryptoPositionAmount_TRS, 0)
,COALESCE(pa.Total_TRSCrypto, 0)
------------------Futures------------------
,COALESCE(pa.TotalMirrorRealFuturesPositionAmount, 0)
,COALESCE(pa.TotalRealFutures, 0)
,COALESCE(pa.TotalFuturesProviderMargin, 0)
,COALESCE(pa.TotalFuturesLockedCash, 0)
--2025-09-29 Stock Margin
,COALESCE(pa.TotalStocksMargin, 0)
,COALESCE(pa.TotalStockMarginLoanValue, 0)
from dwh_daily_process.migration_tables.Fact_SnapshotEquity a
left join TEMP_TABLE_Ext_FSE_PositionChangeLog_CID b
on a.CID = b.CID
join dwh_daily_process.migration_tables.Ext_FSE_TotalPositionAmount pa
on b.CID=pa.CID
where 
right(CAST(DateRangeID AS STRING),4)='1231' and left(CAST(DateRangeID AS STRING),4)=year(V_date)
and 
a.CID NOT IN (SELECT CID FROM dwh_daily_process.migration_tables.Ext_FSE_Fact_SnapshotEquity);
SET V_maxupdatedate = (
SELECT
MAX(UpdateDate) FROM dwh_daily_process.migration_tables.Fact_SnapshotEquity
    ---**** Finish   Treatmant for Position than change CAST(IsSettled AS INT) for column TotalRealStocks & TotalRealCrypto
 LIMIT 1);
-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks)
-- original value 0 /* @@ROWCOUNT not supported */,NULL,NULL,NULL;

MERGE INTO dwh_daily_process.migration_tables.Fact_SnapshotEquity AS a
USING dwh_daily_process.migration_tables.Ext_FSE_Fact_SnapshotEquity AS b
ON a.CID=b.CID
WHEN MATCHED AND 
(a.TotalPositionsAmount<>b.TotalPositionsAmount
or a.TotalCash<>b.TotalCash
or a.InProcessCashouts<>b.InProcessCashouts
or a.TotalMirrorPositionsAmount<>b.TotalMirrorPositionsAmount
or a.TotalStockPositionAmount<>b.TotalStockPositionAmount
or a.TotalMirrorStockPositionAmount	<>b.TotalMirrorStockPositionAmount
or a.TotalCryptoPositionAmount<>b.TotalCryptoPositionAmount               -- added
or a.TotalMirrorCryptoPositionAmount<>b.TotalMirrorCryptoPositionAmount   -- added
or a.TotalRealStocks<>b.TotalRealStocks               -- added
or a.TotalRealCrypto<>b.TotalRealCrypto   -- added
or a.TotalRealCryptoLoan<>b.TotalRealCryptoLoan   -- added
or a.TotalMirrorCash<>b.TotalMirrorCash
or a.TotalStockOrders<>b.TotalStockOrders
or a.TotalMirrorStockOrders<>b.TotalMirrorStockOrders
or a.BonusCredit<>b.BonusCredit
or a.TotalCryptoPositionAmount_TRS<>b.TotalCryptoPositionAmount_TRS
or a.TotalMirrorCryptoPositionAmount_TRS<>b.TotalMirrorCryptoPositionAmount_TRS
or a.Total_TRSCrypto<>b.Total_TRSCrypto
------------------Futures------------------
or a.TotalMirrorRealFuturesPositionAmount<>b.TotalMirrorRealFuturesPositionAmount
or a.TotalRealFutures<>b.TotalRealFutures
or a.TotalFuturesProviderMargin<>b.TotalFuturesProviderMargin
or a.TotalFuturesLockedCash<>b.TotalFuturesLockedCash
------------------StockMargin------------------
or a.TotalStocksMargin<>b.TotalStocksMargin	
or a.TotalStockMarginLoanValue<>b.TotalStockMarginLoanValue
--OR a.RegulationID<>b.RegulationID
) AND CAST(left(CAST(DateRangeID AS STRING),4)+right(CAST(DateRangeID AS STRING),4) AS TIMESTAMP)>=V_maxentrydate THEN UPDATE SET 
DateRangeID=CAST(left(CAST(DateRangeID AS STRING),8)+right(date_format(V_daybefore, 'yyyyMMdd'),4) AS bigint)
,UpdateDate=current_timestamp()
WHEN NOT MATCHED THEN INSERT ( CreditID
,CID
,DateRangeID
,TotalPositionsAmount
,TotalCash
,TotalCashCalculation
,InProcessCashouts
,TotalMirrorPositionsAmount
,TotalStockPositionAmount
,TotalMirrorStockPositionAmount		
,TotalCryptoPositionAmount           -- added
,TotalMirrorCryptoPositionAmount     -- added
,TotalRealStocks           -- added
,TotalRealCrypto     -- added
,TotalRealCryptoLoan
,TotalMirrorCash
,TotalStockOrders
,TotalMirrorStockOrders
,BonusCredit
,RealizedEquity
,Credit
,AUM
,UpdateDate
,TotalCryptoPositionAmount_TRS
,TotalMirrorCryptoPositionAmount_TRS
,Total_TRSCrypto
------------------Futures------------------
,TotalMirrorRealFuturesPositionAmount
,TotalRealFutures
,TotalFuturesProviderMargin
,TotalFuturesLockedCash
------------------StockMargin------------------
,TotalStocksMargin		 
,TotalStockMarginLoanValue
)
VALUES(  b.CreditID
,b.CID
,CAST(date_format(V_date, 'yyyyMMdd')+right(date_format(V_largedate, 'yyyyMMdd'),4) AS bigint)
,b.TotalPositionsAmount
,b.TotalCash
,b.TotalCashCalculation
,b.InProcessCashouts
,b.TotalMirrorPositionsAmount
,b.TotalStockPositionAmount
,b.TotalMirrorStockPositionAmount		
,b.TotalCryptoPositionAmount     ---- added
,b.TotalMirrorCryptoPositionAmount -- added
,b.TotalRealStocks           -- added
,b.TotalRealCrypto     -- added
,b.TotalRealCryptoLoan
,b.TotalMirrorCash
,b.TotalStockOrders
,b.TotalMirrorStockOrders
,b.BonusCredit
,b.RealizedEquity
,b.Credit
,b.TotalMirrorPositionsAmount+b.TotalMirrorCash
,current_timestamp()
,b.TotalCryptoPositionAmount_TRS
,b.TotalMirrorCryptoPositionAmount_TRS
,b.Total_TRSCrypto
------------------Futures------------------
,b.TotalMirrorRealFuturesPositionAmount
,b.TotalRealFutures
,b.TotalFuturesProviderMargin
,b.TotalFuturesLockedCash
------------------StockMargin------------------
,b.TotalStocksMargin	
,b.TotalStockMarginLoanValue
)
;
SET V_rowcount = (
SELECT
SUM(row_count) FROM sys.dm_pdw_request_steps s, sys.dm_pdw_exec_requests r
	--INTO #outputdata
	Where r.request_id = s.request_id 
	and row_count > -1
	and r.`label` = 'Fact_SnapshotEquity'
	--ORDER by r.[end_time] desc;

--OUTPUT
--$action,
--inserted.CID,
--inserted.DateRangeID
--INTO #outputdata;
 LIMIT 1);
INSERT INTO TEMP_TABLE_outputdata
SELECT 'UPDATE' AS action,
CID,
DateRangeID --, *
FROM dwh_daily_process.migration_tables.Fact_SnapshotEquity 
WHERE DateRangeID <> CAST(date_format(V_date, 'yyyyMMdd')+right(date_format(V_largedate, 'yyyyMMdd'),4) AS bigint)
--DateRangeID=convert(bigint,left(convert (Varchar(20),DateRangeID),8)+right(convert (Varchar,@daybefore,112),4))
AND UpdateDate > V_maxupdatedate;
-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks)
-- original value 0 /* @@ROWCOUNT not supported */,NULL,NULL,NULL;
/*INSERT UPDATED RECORDS*/

-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks) INSERT INTO dwh_daily_process.migration_tables.Fact_SnapshotEquity (CreditID ,CID ,DateRangeID ,TotalPositionsAmount ,TotalCash ,TotalCashCalculation ,InProcessCashouts ,TotalMirrorPositionsAmount ,TotalStockPositionAmount ,TotalMirrorStockPositionAmount ,TotalCryptoPositionAmount ,TotalMirrorCryptoPositionAmount ,TotalRealStocks ,TotalRealCrypto ,TotalRealCryptoLoan ,TotalMirrorCash ,TotalStockOrders ,TotalMirrorStockOrders ,BonusCredit ,RealizedEquity ,Credit ,AUM ,UpdateDate ,TotalCryptoPositionAmount_TRS ,TotalMirrorCryptoPositionAmount_TRS ,Total_TRSCrypto ,TotalMirrorRealFuturesPositionAmount ,TotalRealFutures ,TotalFuturesProviderMargin ,TotalFuturesLockedCash ,TotalStocksMargin ,TotalStockMarginLoanValue ) SELECT CreditID ,CID ,CAST(date_format(V_date, 'yyyyMMdd')+right(date_format(V_largedate, 'yyyyMMdd'),4) AS bigint) ,TotalPositionsAmount ,TotalCash ,TotalCashCalculation ,InProcessCashouts ,TotalMirrorPositionsAmount ,TotalStockPositionAmount ,TotalMirrorStockPositionAmount ,TotalCryptoPositionAmount ,TotalMirrorCryptoPositionAmount ,TotalRealStocks ,TotalRealCrypto ,TotalRealCryptoLoan ,TotalMirrorCash ,TotalStockOrders ,TotalMirrorStockOrders ,BonusCredit ,RealizedEquity ,Credit ,TotalMirrorPositionsAmount+TotalMirrorCash ,current_timestamp() ,TotalCryptoPositionAmount_TRS ,TotalMirrorCryptoPositionAmount_TRS ,Total_TRSCrypto ,TotalMirrorRealFuturesPositionAmount ,TotalRealFutures ,TotalFuturesProviderMargin ,TotalFuturesLockedCash ,TotalStocksMargin ,TotalStockMarginLoanValue FROM dwh_daily_process.migration_tables.Ext_FSE_Fact_SnapshotEquity a WHERE EXISTS (SELECT 1 from TEMP_TABLE_outputdata b where Action='UPDATE' AND a.CID=b.CID);
--(SELECT CID from #outputdata b where Action='UPDATE' AND a.CID=b.CID);

SET V_rowcount = (
SELECT
count(*) from TEMP_TABLE_outputdata 
	where Action='UPDATE' 
    
 LIMIT 1);
-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks)
-- original value 0 /* @@ROWCOUNT not supported */,NULL,NULL,NULL;
 
/************************************************************ADD NEW DateRangeID INTO THE TABLE *******************************************************************************************/
--all dates create on a specific date are uniqe

-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks) INSERT INTO dwh_daily_process.migration_tables.Dim_Range (DateRangeID,FromDateID,ToDateID,UpdateDate) SELECT distinct DateRangeID, CAST(left(CAST(DateRangeID AS STRING),8) AS bigint), CAST(left(CAST(DateRangeID AS STRING),4)+right(CAST(DateRangeID AS STRING),4) AS bigint) ,current_timestamp() from TEMP_TABLE_outputdata a where Action='UPDATE' and NOT EXISTS (SELECT DateRangeID from dwh_daily_process.migration_tables.Dim_Range b WHERE a.DateRangeID=b.DateRangeID);
INSERT INTO dwh_daily_process.migration_tables.Dim_Range
(DateRangeID,FromDateID,ToDateID,UpdateDate)
SELECT 
CAST(date_format(V_date, 'yyyyMMdd')+right(date_format(V_largedate, 'yyyyMMdd'),4) AS bigint),
CAST((date_format(V_date, 'yyyyMMdd')) AS INT),
CAST((date_format(V_largedate, 'yyyyMMdd')) AS INT)
,current_timestamp()
where CAST(date_format(V_date, 'yyyyMMdd')+right(date_format(V_largedate, 'yyyyMMdd'),4) AS bigint) not in (SELECT DateRangeID from dwh_daily_process.migration_tables.Dim_Range);
-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks)
-- original value 0 /* @@ROWCOUNT not supported */,NULL,NULL,NULL;
/**************************************************************CLOSE YEAR FOR CIDs*********************************************************************************************************/

IF MONTH(V_date)=01 AND DAY(V_date)=01
THEN
-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks) INSERT INTO dwh_daily_process.migration_tables.Fact_SnapshotEquity (CreditID ,CID ,DateRangeID ,TotalPositionsAmount ,TotalCash ,TotalCashCalculation ,InProcessCashouts ,TotalMirrorPositionsAmount ,TotalStockPositionAmount ,TotalMirrorStockPositionAmount ,TotalCryptoPositionAmount ,TotalMirrorCryptoPositionAmount ,TotalRealStocks ,TotalRealCrypto ,TotalRealCryptoLoan ,TotalMirrorCash ,TotalStockOrders ,TotalMirrorStockOrders ,BonusCredit ,RealizedEquity ,Credit ,AUM ,UpdateDate ,TotalCryptoPositionAmount_TRS ,TotalMirrorCryptoPositionAmount_TRS ,Total_TRSCrypto ,TotalMirrorRealFuturesPositionAmount ,TotalRealFutures ,TotalFuturesProviderMargin ,TotalFuturesLockedCash ,TotalStocksMargin ,TotalStockMarginLoanValue ) SELECT -99/*Fake CreditID for End Of the Year*/ , CID ,CAST(CAST(YEAR(V_date) AS STRING)||'01011231' AS BIGINT) AS DateRangeID ,TotalPositionsAmount ,TotalCash ,TotalCashCalculation ,InProcessCashouts ,TotalMirrorPositionsAmount ,TotalStockPositionAmount ,TotalMirrorStockPositionAmount ,TotalCryptoPositionAmount ,TotalMirrorCryptoPositionAmount ,TotalRealStocks ,TotalRealCrypto ,TotalRealCryptoLoan ,TotalMirrorCash ,TotalStockOrders ,TotalMirrorStockOrders ,BonusCredit ,RealizedEquity ,Credit ,AUM ,current_timestamp() ,TotalCryptoPositionAmount_TRS ,TotalMirrorCryptoPositionAmount_TRS ,Total_TRSCrypto ,TotalMirrorRealFuturesPositionAmount ,TotalRealFutures ,TotalFuturesProviderMargin ,TotalFuturesLockedCash ,TotalStocksMargin ,TotalStockMarginLoanValue FROM dwh_daily_process.migration_tables.Fact_SnapshotEquity WHERE RIGHT(CAST(DateRangeID AS STRING),4)='1231' AND LEFT(CAST(DateRangeID AS STRING),4)=YEAR(DATEADD(YEAR, -1, V_date)) AND CID NOT IN (SELECT CID FROM TEMP_TABLE_outputdata WHERE DateRangeID <> CAST(CAST(YEAR(V_date) AS STRING)||'01011231' AS BIGINT))
SET V_rowcount = (
SELECT
SUM(row_count) FROM sys.dm_pdw_request_steps s, sys.dm_pdw_exec_requests r
	Where r.request_id = s.request_id 
	and row_count > -1
	and r.`label` = 'Fact_SnapshotEquity-Close Year For CIDs'

 LIMIT 1);
-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks)
-- original value 0 /* @@ROWCOUNT not supported */,NULL,NULL,NULL;

END IF;
-- [cleanup] drop session-scoped temp objects so the SP leaves no residue
DROP VIEW IF EXISTS TEMP_TABLE_Ext_FSE_PositionChangeLog_CID;
DROP VIEW IF EXISTS TEMP_TABLE_TotalCashPreviousDate;
DROP TABLE IF EXISTS TEMP_TABLE_outputdata;
END