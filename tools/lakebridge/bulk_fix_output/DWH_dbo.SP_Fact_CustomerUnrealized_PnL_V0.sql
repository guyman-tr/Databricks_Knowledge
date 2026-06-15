USE CATALOG dwh_daily_process;
USE SCHEMA migration_tables;



CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.SP_Fact_CustomerUnrealized_PnL_V0(
IN V_RepDate TIMESTAMP)
LANGUAGE SQL
SQL SECURITY INVOKER
MODIFIES SQL DATA
AS

BEGIN


DECLARE V_dateid  int
;
DECLARE V_StartDate  date ;

DECLARE V_row_count int;
/*delete data from Fact table*/ --in SSIS Package
--EXEC [DWH_dbo].SP_Log_Full 'Fact_CustomerUnrealized_PnL','Delete Row DateModified',@dateid,1,0,NULL,NULL,NULL
--delete from Fact_CustomerUnrealized_PnL where DateModified=@dateid
--EXEC [DWH_dbo].SP_Log_Full 'Fact_CustomerUnrealized_PnL','Delete Row DateModified',@dateid,10,0 /* @@ROWCOUNT not supported */
--EXEC [DWH_dbo].[SP_Fact_CustomerUnrealized_PnL] '2021-05-09'
/********************************************************************************************
Author:      Boris Slutski
Date:        2018-02-08
Description: Update table Fact_CustomerUnrealized_PnL
 
**************************
** Change History
**************************
Date             Author       Description   
----------     ----------   ------------------------------------
28/08/2014        Max         hard-coded selections of source database changed to synonyms
07/04/2019        Boris       not must update History for CAST(IsSettled AS INT) [DWH_dbo].Ext_FCUPNL_History_Position  
03/03/2020	      Boris       change Price table to [DWH_dbo].Ext_FCUPNL_CurrencyPriceMaxDateWithSplit
08/03/2020        Boris       calculate net progit to AS DECIMAL(16, 2) from AS DECIMAL(16, 4)
07/06/2020        Boris       upated CAST(IsSettled AS INT) to PartialClose Positions
12/07/2020        Boris       Add FullCommissionByUnitsStocksReal & FullCommissionByUnitsCryptoReal
24/01/2021        Boris        Change defenition  from InstrumentID>1000 AND InstrumentID <100000 to InstrumentTypeID in(5,6)
03/01/2021        Boris       Union all partial close position to one for calculate Unrealize Pnl
19/12/2021        Adi F       add FullCommissionByUnitsStocksCFD ,FullCommissionByUnitsCryptoCFD
03/02/2022		  Inbal BML	  add SettlementTypeID and TRS fileds
2022-04-11        Boris       Change logic for temp table #Equity (instead V_Liabilities  using a table Fact_SnapshotEquity), JIRA TICKET DS-3062
2022-08-07        Adi F       Add delete from dbo.[Fact_CustomerUnrealized_PnL] - this a bugfix found on 2022-07-27 
*********************************************************************************************/



--DECLARE @RepDate DATETIME ='2019-02-02'
--DECLARE @ReportDate DATETIME
--SET @ReportDate = dateadd(day,1,@RepDate)
--DECLARE @RepDate DATETIME ='20200101'

set V_dateid=CAST(date_format(V_RepDate, 'yyyyMMdd') AS int)
;
SET V_StartDate = DATEADD(day, 1, V_RepDate);
---declare @dateID INT = convert(int,convert(varchar(8),@RepDate,112))
MERGE INTO dwh_daily_process.migration_tables.Ext_FCUPNL_Trade_Position A_TGT USING (
SELECT * 
from dwh_daily_process.migration_tables.Ext_FCUPNL_Trade_Position a
INNER JOIN dwh_daily_process.migration_tables.Ext_FCUPNL_PositionChangeLog b on a.PositionID = b.PositionID /*
update [DWH_dbo].Ext_FCUPNL_History_Position  
set IsSettled = CAST(b.PreviousIsSettled AS INT)
from [DWH_dbo].Ext_FCUPNL_History_Position a 
join [DWH_dbo].Ext_FCUPNL_PositionChangeLog b
on a.PositionID = b.PositionID or a.OriginalPositionID = b.PositionID
*/--Boris Pinsky 2022-08-10

QUALIFY ROW_NUMBER() OVER (PARTITION BY a.PositionID ORDER BY 1) = 1
)
ON a.PositionID = A_TGT.PositionID
WHEN MATCHED THEN UPDATE SET
IsSettled = CAST(b.PreviousIsSettled AS INT);
MERGE INTO dwh_daily_process.migration_tables.Ext_FCUPNL_History_Position A_TGT USING (
SELECT * 
from dwh_daily_process.migration_tables.Ext_FCUPNL_History_Position a
INNER JOIN dwh_daily_process.migration_tables.Ext_FCUPNL_PositionChangeLog b on a.PositionID = b.PositionID

QUALIFY ROW_NUMBER() OVER (PARTITION BY a.PositionID ORDER BY 1) = 1
)
ON a.PositionID = A_TGT.PositionID
WHEN MATCHED THEN UPDATE SET
IsSettled = CAST(b.PreviousIsSettled AS INT);
MERGE INTO dwh_daily_process.migration_tables.Ext_FCUPNL_History_Position A_TGT USING (
SELECT * 
from dwh_daily_process.migration_tables.Ext_FCUPNL_History_Position a
INNER JOIN dwh_daily_process.migration_tables.Ext_FCUPNL_PositionChangeLog b on a.OriginalPositionID = b.PositionID ------ Get prices
 ---Delete records [DWH_dbo].Fact_CustomerUnrealized_PnL ---


QUALIFY ROW_NUMBER() OVER (PARTITION BY a.OriginalPositionID ORDER BY 1) = 1
)
ON a.OriginalPositionID = A_TGT.OriginalPositionID
WHEN MATCHED THEN UPDATE SET
IsSettled = CAST(b.PreviousIsSettled AS INT);
DELETE from dwh_daily_process.migration_tables.Fact_CustomerUnrealized_PnL
WHERE DateModified = V_dateid;




--drop table If Exists #Prices
DROP VIEW IF EXISTS TEMP_TABLE_Prices;
-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks)
CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_Prices  
 AS
	SELECT PC60.InstrumentID
		 , BidLast AS RateBid
		 , AskLast AS RateAsk
		 , DateFrom
		 ,Split.MinDate as SplitMinDate
		 ,Split.MaxDate as SplitMaxDate
		 ,Split.PriceRatio
		 ,Split.AmountRatio
		 ,Split.PriceRatioUnAdjusted
		 ,Split.AmountRatioUnAdjusted
		 ,AskLastWithoutSpread
		 ,BidLastWithoutSpread
	--INTO #Prices
	FROM
		(
		 SELECT row_number() OVER (PARTITION BY InstrumentID ORDER BY `Occurred` DESC) rn -----------------******************
			  , InstrumentID
			  , cast(AskSpreaded as decimal(16,8)) AskLast
			  , cast(BidSpreaded as decimal(16,8)) BidLast
			  , cast(Ask as decimal(16,8)) AskLastWithoutSpread
			  , cast(Bid as decimal(16,8)) BidLastWithoutSpread
			  , `OccurredDate` AS DateFrom
		 FROM dwh_daily_process.migration_tables.Ext_FCUPNL_CurrencyPriceMaxDateWithSplit----Ext_FCUPNL_GetSpreadedPriceCandle60MinSplitted WITH (NOLOCK)
		 --WHERE DateFrom <= @RepDate
		) PC60
LEFT JOIN dwh_daily_process.migration_tables.Ext_FCUPNL_History_SplitRatio Split 
	ON PC60.InstrumentID = Split.InstrumentID
	AND PC60.DateFrom < Split.MaxDate
	AND PC60.DateFrom > Split.MinDate	
	WHERE rn = 1;
	--ORDER BY InstrumentID
call `dbo`.`LastRowCount`( 'Prices1' , V_row_count OUT

	--SELECT @row_count = row_count
	-- FROM sys.dm_pdw_request_steps s, sys.dm_pdw_exec_requests r
	--Where r.request_id = s.request_id 
	--and row_count > -1
	--and r.[label] = 'Prices1'
	--ORDER by r.[end_time] desc;


     CREATE CLUSTERED columnstore INDEX TEMP_TABLE_InstInd ON TEMP_TABLE_Prices

);
-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks)
DROP VIEW IF EXISTS TEMP_TABLE_from_date;
CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_from_date  
 AS
SELECT a.*
		,ROW_NUMBER() OVER (PARTITION BY a.CID ORDER BY a.ValidFrom) AS rn
		,CASE WHEN a.CID = b.CID AND a.AccountTypeID <> b.AccountTypeID THEN 1 END AS change
--INTO #from_date 
FROM dwh_daily_process.migration_tables.Ext_FCUPNL_BackOfficeCustomer a
	LEFT JOIN dwh_daily_process.migration_tables.Ext_FCUPNL_BackOfficeCustomer b
		ON a.CID = b.CID 
		AND  a.rank = b.rank+1 
WHERE (CASE WHEN a.CID = b.CID AND a.AccountTypeID <> b.AccountTypeID THEN 1 END =1) OR (b.rank IS NULL AND b.AccountTypeID IS NULL);

 CREATE CLUSTERED columnstore INDEX ix_from_date ON TEMP_TABLE_from_date;


--drop table if Exists #to_date
DROP VIEW IF EXISTS TEMP_TABLE_to_date;
CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_to_date  
 AS
SELECT a.*
		,ROW_NUMBER() OVER (PARTITION BY a.CID ORDER BY a.ValidFrom) AS rn
		,CASE WHEN a.CID = b.CID AND  a.AccountTypeID <> b.AccountTypeID THEN 1 END AS change
--INTO #to_date
FROM dwh_daily_process.migration_tables.Ext_FCUPNL_BackOfficeCustomer a
	LEFT JOIN dwh_daily_process.migration_tables.Ext_FCUPNL_BackOfficeCustomer b
		ON a.CID=b.CID 
		AND a.rank+1 = b.rank
WHERE (CASE WHEN a.CID = b.CID AND a.AccountTypeID <> b.AccountTypeID THEN 1 END =1) OR (b.rank IS NULL AND b.AccountTypeID IS NULL);

 CREATE CLUSTERED columnstore INDEX ix_to_date ON TEMP_TABLE_to_date;


--drop table if Exists #fund_dates
DROP VIEW IF EXISTS TEMP_TABLE_fund_dates;
CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_fund_dates  
 AS
SELECT a.CID
		,a.AccountTypeID
		,a.ValidFrom
		,b.ValidTo
--INTO #fund_dates
FROM TEMP_TABLE_from_date a
	JOIN TEMP_TABLE_to_date b
		ON a.CID = b.CID 
		AND a.rn=b.rn
WHERE a.AccountTypeID = 9;

 CREATE CLUSTERED columnstore INDEX ix_fund_dates ON TEMP_TABLE_fund_dates;

--drop table if Exists #copyfund
DROP VIEW IF EXISTS TEMP_TABLE_copyfund;
CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_copyfund  
 AS
SELECT a.CID
		,a.ParentCID
		,a.MirrorID
		,a.Occurred
		,b.ValidFrom
		,b.ValidTo
--INTO #copyfund
FROM dwh_daily_process.migration_tables.Ext_FCUPNL_History_Mirror a
	JOIN TEMP_TABLE_fund_dates b
		ON a.ParentCID = b.CID
WHERE a.MirrorOperationID = 1;

 CREATE CLUSTERED COLUMNSTORE INDEX ix_copyfund ON TEMP_TABLE_copyfund;

/*******************/
-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks)
DROP VIEW IF EXISTS TEMP_TABLE_OpenPositions;
CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_OpenPositions  
 AS
	select a.PositionID
	,a.CID
	,a.MirrorID
	,a.InstrumentID
	,a.OpenOccurred
	,a.CloseOccurred
			 , CASE WHEN OpenOccurred < b.SplitMaxDate AND COALESCE(CloseOccurred, '21000101') >= b.SplitMaxDate
					THEN CAST(a.AmountInUnitsDecimal / b.AmountRatio as decimal (16,6)) ELSE
		 nullif(a.AmountInUnitsDecimal,0) END as AmountInUnitsDecimal
			 , CASE WHEN OpenOccurred < b.SplitMaxDate AND COALESCE(CloseOccurred, '21000101') >= b.SplitMaxDate
					THEN CAST(a.InitForexRate / b.PriceRatio as decimal (16,8)) ELSE
		 a.InitForexRate END as InitForexRate
	,a.SpreadedPipBid
	, a.SpreadedPipAsk
	,a.IsBuy
	, LastOpConversionRate
	, Commission
	, FullCommission
	,b.DateFrom as PriceDateFrom
	,CASE WHEN IsDiscounted = 1
			THEN
			(
			CASE 
				WHEN OpenOccurred < b.SplitMaxDate AND COALESCE(CloseOccurred, '21000101') >= b.SplitMaxDate
					THEN CAST(b.BidLastWithoutSpread / b.PriceRatio as decimal (16,8)) 
				WHEN OpenOccurred < b.SplitMaxDate and  CloseOccurred < b.SplitMaxDate
					THEN  CAST(b.BidLastWithoutSpread / b.PriceRatio as decimal (16,8)) 
				ELSE b.BidLastWithoutSpread 
			END 
			)
			ELSE
			(
			CASE 
				WHEN OpenOccurred < b.SplitMaxDate AND COALESCE(CloseOccurred, '21000101') >= b.SplitMaxDate
					THEN CAST(b.RateBid / b.PriceRatio as decimal (16,8)) 
				WHEN OpenOccurred < b.SplitMaxDate and  CloseOccurred < b.SplitMaxDate
					THEN  CAST(b.RateBid / b.PriceRatio as decimal (16,8)) 
				ELSE b.RateBid 
			END
			)
			END
			AS RateBid
	,
	----------CASE WHEN IsDiscounted = 1
	----------		THEN
	----------		(
	----------		CASE 
	----------			WHEN OpenOccurred < b.SplitMaxDate AND ISNULL(CloseOccurred, '21000101') >= b.SplitMaxDate
	----------				THEN CAST(b.RateAsk / b.PriceRatio as decimal (16,8)) 
	----------			WHEN OpenOccurred < b.SplitMaxDate and  CloseOccurred < b.SplitMaxDate
	----------				THEN  CAST(b.RateAsk / b.PriceRatio as decimal (16,8)) 
	----------			ELSE b.RateAsk 
	----------		END 
	----------		)
	----------		ELSE
	----------		(
			CASE 
				WHEN OpenOccurred < b.SplitMaxDate AND COALESCE(CloseOccurred, '21000101') >= b.SplitMaxDate
					THEN CAST(b.RateAsk / b.PriceRatio as decimal (16,8)) 
				WHEN OpenOccurred < b.SplitMaxDate and  CloseOccurred < b.SplitMaxDate
					THEN  CAST(b.RateAsk / b.PriceRatio as decimal (16,8)) 
				ELSE b.RateAsk 
			END 
			--------------)
			--------------END
			AS RateAsk
	,b.SplitMinDate
	,b.SplitMaxDate
	,b.PriceRatio
	,b.AmountRatio
	,b.PriceRatioUnAdjusted
	,b.AmountRatioUnAdjusted
	,CASE WHEN copyfund.CID IS NOT NULL THEN 1 END AS CopyFund
	, CommissionByUnits
	, FullCommissionByUnits
	, CAST(IsSettled AS INT)
	, CAST(IsDiscounted AS INT)
	, ParentPositionID
	, CASE WHEN ParentPositionID = 0 THEN 0 ELSE 1 END AS ConnectedGuruCopies
	,OriginalPositionID
	,SettlementTypeID
	--into #OpenPositions
	from 
	(
	SELECT PositionID
		 , CID
		 , MirrorID
		 , InstrumentID
		 , OpenOccurred
		 , CloseOccurred
		 , AmountInUnitsDecimal
		 , InitForexRate
		 , SpreadedPipBid
		 , SpreadedPipAsk
		 , IsBuy
		 , LastOpConversionRate
		 , Commission
		 , FullCommission
		 , CAST(IsSettled AS INT)
		 , CommissionByUnits
		 , `FullCommissionByUnits`
		 , CAST(IsDiscounted AS INT)
		 , ParentPositionID
		 , PositionID as OriginalPositionID
		 , SettlementTypeID
	FROM dwh_daily_process.migration_tables.Ext_FCUPNL_Trade_Position 
	--WHERE  Occurred< @ReportDate 
	union
	SELECT PositionID
		 , CID
		 , MirrorID
		 , InstrumentID
		 , OpenOccurred
		 , CloseOccurred
		 , AmountInUnitsDecimal
		 , InitForexRate
		 , SpreadedPipBid
		 , SpreadedPipAsk
		 , IsBuy
		 , LastOpConversionRate
		 , Commission
		 , FullCommission
		 , CAST(IsSettled AS INT)
		 , CommissionByUnits
		 , `FullCommissionByUnits`
		 , CAST(IsDiscounted AS INT)
		 , ParentPositionID
		 , OriginalPositionID
		 , SettlementTypeID
	FROM dwh_daily_process.migration_tables.Ext_FCUPNL_History_Position   
	--WHERE  OpenOccurred < @ReportDate
	--	AND CloseOccurred > @ReportDate
	) a
LEFT JOIN TEMP_TABLE_Prices b
ON a.InstrumentID = b.InstrumentID
LEFT JOIN TEMP_TABLE_copyfund copyfund
	ON a.MirrorID = copyfund.MirrorID
	AND a.OpenOccurred >= copyfund.ValidFrom 
	AND a.OpenOccurred < copyfund.ValidTo
	;
call `dbo`.`LastRowCount`( 'OpenPositions2' , V_row_count OUT

	--SELECT @row_count = row_count
	-- FROM sys.dm_pdw_request_steps s, sys.dm_pdw_exec_requests r
	--Where r.request_id = s.request_id 
	--and row_count > -1
	--and r.[label] = 'OpenPositions2'
	--ORDER by r.[end_time] desc;



 CREATE CLUSTERED columnstore INDEX TEMP_TABLE_PosInd on TEMP_TABLE_OpenPositions 
 
);
-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks)
DROP VIEW IF EXISTS TEMP_TABLE_OpenPositionsFinal;
CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_OpenPositionsFinal  
 AS

 SELECT 
  CID
, OriginalPositionID  as PositionID
, InstrumentID
, MirrorID
, Sum(Commission) as Commission
, Sum(FullCommission) FullCommission
, InitForexRate
, SpreadedPipBid
, SpreadedPipAsk
, CopyFund
, IsBuy
, RateBid
, RateAsk
, Sum(AmountInUnitsDecimal) as AmountInUnitsDecimal
, CAST(IsSettled AS INT) 
, sum(CommissionByUnits) as CommissionByUnits
, sum(FullCommissionByUnits) as FullCommissionByUnits
, ConnectedGuruCopies
, SettlementTypeID
from TEMP_TABLE_OpenPositions
--where PositionID  in (1011440333, 1287373251)
group by
CID
, OriginalPositionID 
, InstrumentID
, MirrorID
, SpreadedPipBid
, SpreadedPipAsk
, CopyFund
, IsBuy
, RateBid
, InitForexRate
, RateAsk
, CAST(IsSettled AS INT) 
, ConnectedGuruCopies
, SettlementTypeID;



--drop table if Exists #UnrealizedPnL
DROP VIEW IF EXISTS TEMP_TABLE_UnrealizedPnL;
-- Calculate unrealized NetProfit

-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks)
CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_UnrealizedPnL  
 AS
	SELECT HPOS.CID
		, HPOS.PositionID
		, HPOS.InstrumentID
		, HPOS.MirrorID
		, HPOS.Commission
		, HPOS.FullCommission
		, HPOS.InitForexRate
		, HPOS.SpreadedPipBid
		, HPOS.SpreadedPipAsk
		, HPOS.CopyFund
		, 
				cast((
		   CASE HPOS.IsBuy
				WHEN 1
					THEN COALESCE(HPOS.RateBid, 0) - HPOS.InitForexRate
					ELSE HPOS.InitForexRate - COALESCE(HPOS.RateAsk, 0)
			* 
			cast(
			CASE
				WHEN Pair.SellCurrencyID = 1
					THEN 1.00
				WHEN Pair.BuyCurrencyID = 1
					THEN (1.00 / 
								CASE HPOS.IsBuy
								WHEN 1
	                			THEN HPOS.RateBid
								ELSE HPOS.RateAsk
								END
								)
	        WHEN (Pair.BuyCurrencyID <> 1 AND Pair.SellCurrencyID <> 1)
	            THEN coalesce(1.00 / 
				CASE HPOS.IsBuy WHEN 1 THEN I2Price.RateBid ELSE I2Price.RateAsk END, 
				CASE HPOS.IsBuy WHEN 1 THEN I3Price.RateBid ELSE I3Price.RateAsk END, 1.00)
	        ELSE 1.00
			END 
			AS DECIMAL(19,4)) 
		* HPOS.AmountInUnitsDecimal) AS DECIMAL(16,2))

		

		AS CalculatedNetProfit
		, CAST(IsSettled AS INT) 
		, Pair.InstrumentTypeID
		, CommissionByUnits
		, FullCommissionByUnits
		, ConnectedGuruCopies
		, SettlementTypeID
--INTO #UnrealizedPnL
	FROM TEMP_TABLE_OpenPositionsFinal  HPOS 
	LEFT JOIN dwh_daily_process.migration_tables.Ext_FCUPNL_Dictionary_Instrument Pair 
		ON Pair.InstrumentID = HPOS.InstrumentID
	LEFT JOIN TEMP_TABLE_Prices PairPrice 
		ON Pair.InstrumentID = PairPrice.InstrumentID
	LEFT JOIN dwh_daily_process.migration_tables.Ext_FCUPNL_Dictionary_Instrument I2 
		ON I2.InstrumentID <> Pair.InstrumentID -- This is so I won't get doubled records.
		AND I2.SellCurrencyID = Pair.SellCurrencyID AND I2.BuyCurrencyID = 1 -- USD
	LEFT JOIN TEMP_TABLE_Prices I2Price 
		ON I2Price.InstrumentID = I2.InstrumentID
	LEFT JOIN dwh_daily_process.migration_tables.Ext_FCUPNL_Dictionary_Instrument I3 
		ON I3.InstrumentID <> Pair.InstrumentID -- This is so I won't get doubled records.
		AND I3.BuyCurrencyID = Pair.SellCurrencyID AND I3.SellCurrencyID = 1 -- USD
	LEFT JOIN TEMP_TABLE_Prices I3Price 
		ON I3Price.InstrumentID = I3.InstrumentID
	;
call `dbo`.`LastRowCount`( 'UnrealizedPnL4' , V_row_count OUT

	--SELECT @row_count = row_count
	-- FROM sys.dm_pdw_request_steps s, sys.dm_pdw_exec_requests r
	--Where r.request_id = s.request_id 
	--and row_count > -1
	--and r.[label] = 'UnrealizedPnL4'
	--ORDER by r.[end_time] desc;

 CREATE CLUSTERED columnstore INDEX `IX_tmp_UnrealizedPnL` ON TEMP_TABLE_UnrealizedPnL

);
-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks)
-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks)
DROP VIEW IF EXISTS TEMP_TABLE_price0;
CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_price0  
 AS
select b.InstrumentID, b.Name, AskLast as Ask, BidLast as Bid, BuyCurrencyID, SellCurrencyID, InstrumentTypeID
--into #price0
from (select InstrumentID, BidLast, AskLast 
       from (
	   --select ROW_NUMBER() over (partition by InstrumentID order by DateFrom desc) rank, InstrumentID, AskLast, BidLast 
	   --      from [DWH_dbo].Ext_FCUPNL_CurrencyPriceMaxDateWithSplit ---Ext_FCUPNL_GetSpreadedPriceCandle60MinSplitted 
			 --where DateFrom <= @StartDate
			 SELECT row_number() OVER (PARTITION BY InstrumentID ORDER BY Occurred DESC) rank -----------------******************
			  , InstrumentID
			  , cast(AskSpreaded as decimal(16,8)) AskLast
			  , cast(BidSpreaded as decimal(16,8)) BidLast
			  , cast(Ask as decimal(16,8)) AskLastWithoutSpread
			  , cast(Bid as decimal(16,8)) BidLastWithoutSpread
			  ,OccurredDate as DateFrom
		 FROM dwh_daily_process.migration_tables.Ext_FCUPNL_CurrencyPriceMaxDateWithSplit
			 ) prices where prices.rank = 1 ) a
join dwh_daily_process.migration_tables.Ext_FCUPNL_Dictionary_Instrument b
on a.InstrumentID=b.InstrumentID;

--drop table if exists #final_NOP_Notional
DROP VIEW IF EXISTS TEMP_TABLE_final_NOP_Notional;
CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_final_NOP_Notional  
 AS
select a.CID
,sum(AmountInUnitsDecimal * (case when IsBuy = 1 then b.Bid else b.Ask end) * (case when IsBuy = 1 then 1 else -1 end) 
*(case when b.SellCurrencyID=1 then 1.00 
       when b.BuyCurrencyID=1 then 1.00/(case when IsBuy = 1 then b.Bid else b.Ask end) 
	     when b.SellCurrencyID <> 1 and b.BuyCurrencyID <> 1 and c.BuyCurrencyID = 1 then 1.00/(case when IsBuy = 1 then c.Bid ELSE
c.Ask 
end) 
       when b.SellCurrencyID <> 1 and b.BuyCurrencyID <> 1 and d.SellCurrencyID = 1 then (case when IsBuy = 1 then d.Bid ELSE
d.Ask 
end)
	   
end
  ))
as NOP
, sum(abs(AmountInUnitsDecimal * (case when IsBuy = 1 then b.Bid else b.Ask end) * (case when IsBuy = 1 then 1 else -1 end) 
*(case when b.SellCurrencyID=1 then 1.00 
       when b.BuyCurrencyID=1 then 1.00/(case when IsBuy = 1 then b.Bid else b.Ask end) 
	     when b.SellCurrencyID <> 1 and b.BuyCurrencyID <> 1 and c.BuyCurrencyID = 1 then 1.00/(case when IsBuy = 1 then c.Bid ELSE
c.Ask 
end) 
       when b.SellCurrencyID <> 1 and b.BuyCurrencyID <> 1 and d.SellCurrencyID = 1 then (case when IsBuy = 1 then d.Bid ELSE
d.Ask 
end)
	   
end
  )))
as Notional
, sum(AmountInUnitsDecimal * (case when IsBuy = 1 then b.Bid else b.Ask end) * (case when IsBuy = 1 then 1 else -1 end) 
*(case	when b.InstrumentTypeID <> 10 then 0
		when b.SellCurrencyID=1 then 1.00 
		when b.BuyCurrencyID=1 then 1.00/(case when IsBuy = 1 then b.Bid else b.Ask end) 
		when b.SellCurrencyID <> 1 and b.BuyCurrencyID <> 1 and c.BuyCurrencyID = 1 then 1.00/(case when IsBuy = 1 then c.Bid ELSE
c.Ask 
end) 
		when b.SellCurrencyID <> 1 and b.BuyCurrencyID <> 1 and d.SellCurrencyID = 1 then (case when IsBuy = 1 then d.Bid ELSE
d.Ask 
end)
		
end
  ))
as NOP_Crypto
, sum(abs(AmountInUnitsDecimal * (case when IsBuy = 1 then b.Bid else b.Ask end) * (case when IsBuy = 1 then 1 else -1 end) 
*(case	when b.InstrumentTypeID <> 10 then 0 
		when b.SellCurrencyID=1 then 1.00 
		when b.BuyCurrencyID=1 then 1.00/(case when IsBuy = 1 then b.Bid else b.Ask end) 
		when b.SellCurrencyID <> 1 and b.BuyCurrencyID <> 1 and c.BuyCurrencyID = 1 then 1.00/(case when IsBuy = 1 then c.Bid else c.Ask end) 
		when b.SellCurrencyID <> 1 and b.BuyCurrencyID <> 1 and d.SellCurrencyID = 1 then (case when IsBuy = 1 then d.Bid else d.Ask end)
		end
  )))
as Notional_Crypto

-----
,  
sum(AmountInUnitsDecimal * (case when IsBuy = 1 then b.Bid else b.Ask end) * (case when IsBuy = 1 then 1 else -1 end) 
*(case when b.SellCurrencyID=1 then 1.00 
       when b.BuyCurrencyID=1 then 1.00/(case when IsBuy = 1 then b.Bid else b.Ask end) 
	     when b.SellCurrencyID <> 1 and b.BuyCurrencyID <> 1 and c.BuyCurrencyID = 1 then 1.00/(case when IsBuy = 1 then c.Bid else c.Ask end) 
       when b.SellCurrencyID <> 1 and b.BuyCurrencyID <> 1 and d.SellCurrencyID = 1 then (case when IsBuy = 1 then d.Bid else d.Ask end)
	   end
  )
  *(case when IsSettled= 0 then 1 else 0 end )
  )
as NOP_CFD
, 
sum(abs(AmountInUnitsDecimal * (case when IsBuy = 1 then b.Bid else b.Ask end) * (case when IsBuy = 1 then 1 else -1 end) 
*(case when b.SellCurrencyID=1 then 1.00 
       when b.BuyCurrencyID=1 then 1.00/(case when IsBuy = 1 then b.Bid else b.Ask end) 
	     when b.SellCurrencyID <> 1 and b.BuyCurrencyID <> 1 and c.BuyCurrencyID = 1 then 1.00/(case when IsBuy = 1 then c.Bid else c.Ask end) 
       when b.SellCurrencyID <> 1 and b.BuyCurrencyID <> 1 and d.SellCurrencyID = 1 then (case when IsBuy = 1 then d.Bid else d.Ask end)
	   end
    )
  *(case when IsSettled= 0 then 1 else 0 end )
  ))
as Notional_CFD
,
sum(AmountInUnitsDecimal * (case when IsBuy = 1 then b.Bid else b.Ask end) * (case when IsBuy = 1 then 1 else -1 end) 
*(case	when b.InstrumentTypeID <> 10 then 0
		when b.SellCurrencyID=1 then 1.00 
		when b.BuyCurrencyID=1 then 1.00/(case when IsBuy = 1 then b.Bid else b.Ask end) 
		when b.SellCurrencyID <> 1 and b.BuyCurrencyID <> 1 and c.BuyCurrencyID = 1 then 1.00/(case when IsBuy = 1 then c.Bid else c.Ask end) 
		when b.SellCurrencyID <> 1 and b.BuyCurrencyID <> 1 and d.SellCurrencyID = 1 then (case when IsBuy = 1 then d.Bid else d.Ask end)
		end
  )
  *(case when IsSettled= 0 then 1 else 0 end )
  )
as NOP_Crypto_CFD
, 
 sum(abs(AmountInUnitsDecimal * (case when IsBuy = 1 then b.Bid else b.Ask end) * (case when IsBuy = 1 then 1 else -1 end) 
*(case	when b.InstrumentTypeID <> 10 then 0 
		when b.SellCurrencyID=1 then 1.00 
		when b.BuyCurrencyID=1 then 1.00/(case when IsBuy = 1 then b.Bid else b.Ask end) 
		when b.SellCurrencyID <> 1 and b.BuyCurrencyID <> 1 and c.BuyCurrencyID = 1 then 1.00/(case when IsBuy = 1 then c.Bid else c.Ask end) 
		when b.SellCurrencyID <> 1 and b.BuyCurrencyID <> 1 and d.SellCurrencyID = 1 then (case when IsBuy = 1 then d.Bid else d.Ask end)
		end
    )
  *(case when IsSettled= 0 then 1 else 0 end )
  ))
as Notional_Crypto_CFD
------ Stocks
, sum(AmountInUnitsDecimal * (case when IsBuy = 1 then b.Bid else b.Ask end) * (case when IsBuy = 1 then 1 else -1 end) 
*(case	when b.InstrumentTypeID not in (5,6) then 0
		when b.SellCurrencyID=1 then 1.00 
		when b.BuyCurrencyID=1 then 1.00/(case when IsBuy = 1 then b.Bid else b.Ask end) 
		when b.SellCurrencyID <> 1 and b.BuyCurrencyID <> 1 and c.BuyCurrencyID = 1 then 1.00/(case when IsBuy = 1 then c.Bid else c.Ask end) 
		when b.SellCurrencyID <> 1 and b.BuyCurrencyID <> 1 and d.SellCurrencyID = 1 then (case when IsBuy = 1 then d.Bid else d.Ask end)
		end
  ))
as NOP_Stock
, sum(abs(AmountInUnitsDecimal * (case when IsBuy = 1 then b.Bid else b.Ask end) * (case when IsBuy = 1 then 1 else -1 end) 
*(case	when b.InstrumentTypeID  not in (5,6) then 0 
		when b.SellCurrencyID=1 then 1.00 
		when b.BuyCurrencyID=1 then 1.00/(case when IsBuy = 1 then b.Bid else b.Ask end) 
		when b.SellCurrencyID <> 1 and b.BuyCurrencyID <> 1 and c.BuyCurrencyID = 1 then 1.00/(case when IsBuy = 1 then c.Bid else c.Ask end) 
		when b.SellCurrencyID <> 1 and b.BuyCurrencyID <> 1 and d.SellCurrencyID = 1 then (case when IsBuy = 1 then d.Bid else d.Ask end)
		end
  )))
as Notional_Stock
-------------
,
sum(AmountInUnitsDecimal * (case when IsBuy = 1 then b.Bid else b.Ask end) * (case when IsBuy = 1 then 1 else -1 end) 
*(case	when b.InstrumentTypeID not in (5,6) then 0
		when b.SellCurrencyID=1 then 1.00 
		when b.BuyCurrencyID=1 then 1.00/(case when IsBuy = 1 then b.Bid else b.Ask end) 
		when b.SellCurrencyID <> 1 and b.BuyCurrencyID <> 1 and c.BuyCurrencyID = 1 then 1.00/(case when IsBuy = 1 then c.Bid else c.Ask end) 
		when b.SellCurrencyID <> 1 and b.BuyCurrencyID <> 1 and d.SellCurrencyID = 1 then (case when IsBuy = 1 then d.Bid else d.Ask end)
		end
  )
  *(case when IsSettled= 0 then 1 else 0 end )
  )
as NOP_Stock_CFD
, 
 sum(abs(AmountInUnitsDecimal * (case when IsBuy = 1 then b.Bid ELSE
b.Ask 
end) * (case when IsBuy = 1 then 1 else -1 end) 
*(case	when b.InstrumentTypeID not in (5,6) then 0 
		when b.SellCurrencyID=1 then 1.00 
		when b.BuyCurrencyID=1 then 1.00/(case when IsBuy = 1 then b.Bid else b.Ask end) 
		when b.SellCurrencyID <> 1 and b.BuyCurrencyID <> 1 and c.BuyCurrencyID = 1 then 1.00/(case when IsBuy = 1 then c.Bid else c.Ask end) 
		when b.SellCurrencyID <> 1 and b.BuyCurrencyID <> 1 and d.SellCurrencyID = 1 then (case when IsBuy = 1 then d.Bid else d.Ask end)
		end
    )
  *(case when IsSettled= 0 then 1 else 0 end )
  ))
as Notional_Stock_CFD
,
sum(AmountInUnitsDecimal * (case when IsBuy = 1 then b.Bid ELSE
b.Ask 
end) * (case when IsBuy = 1 then 1 else -1 end) 
*(case        when b.InstrumentTypeID <> 10 then 0
                when b.SellCurrencyID=1 then 1.00 
                when b.BuyCurrencyID=1 then 1.00/(case when IsBuy = 1 then b.Bid else b.Ask end) 
                when b.SellCurrencyID <> 1 and b.BuyCurrencyID <> 1 and c.BuyCurrencyID = 1 then 1.00/(case when IsBuy = 1 then c.Bid else c.Ask end) 
                when b.SellCurrencyID <> 1 and b.BuyCurrencyID <> 1 and d.SellCurrencyID = 1 then (case when IsBuy = 1 then d.Bid else d.Ask end)
                end
  )
  *(case when IsSettled= 0 then 1 else 0 end )
  *(case when  SettlementTypeID=2 then 1 else 0 end )
  )
  as NOP_Crypto_TRS
 ,
 sum(abs(AmountInUnitsDecimal * (case when IsBuy = 1 then b.Bid ELSE
b.Ask 
end) * (case when IsBuy = 1 then 1 else -1 end) 
*(case        when b.InstrumentTypeID <> 10 then 0 
                when b.SellCurrencyID=1 then 1.00 
                when b.BuyCurrencyID=1 then 1.00/(case when IsBuy = 1 then b.Bid else b.Ask end) 
                when b.SellCurrencyID <> 1 and b.BuyCurrencyID <> 1 and c.BuyCurrencyID = 1 then 1.00/(case when IsBuy = 1 then c.Bid else c.Ask end) 
                when b.SellCurrencyID <> 1 and b.BuyCurrencyID <> 1 and d.SellCurrencyID = 1 then (case when IsBuy = 1 then d.Bid else d.Ask end)
                end
    )
  *(case when IsSettled= 0 then 1 else 0 end )
  *(case when  SettlementTypeID=2 then 1 else 0 end )
  ))
as Notional_Crypto_TRS

-----
--into #final_NOP_Notional 
from  (select  CID, MirrorID, InstrumentID, AmountInUnitsDecimal, LastOpConversionRate, InitForexRate, IsBuy, Commission, CAST(IsSettled AS INT), SettlementTypeID from dwh_daily_process.migration_tables.Ext_FCUPNL_Trade_Position
         where V_StartDate > OpenOccurred
       union all
	   select CID, MirrorID, InstrumentID, AmountInUnitsDecimal,  LastOpConversionRate, InitForexRate, IsBuy, Commission, CAST(IsSettled AS INT), SettlementTypeID from dwh_daily_process.migration_tables.Ext_FCUPNL_History_Position
	     where  V_StartDate > OpenOccurred and V_StartDate < CloseOccurred
		) a
join TEMP_TABLE_price0 b
on a.InstrumentID=b.InstrumentID
left join TEMP_TABLE_price0 c
on b.SellCurrencyID = c.SellCurrencyID and c.BuyCurrencyID = 1 and b.BuyCurrencyID <> 1
left join TEMP_TABLE_price0 d
on b.SellCurrencyID = d.BuyCurrencyID and d.SellCurrencyID = 1 and b.SellCurrencyID <> 1
--join Customer.Customer e on a.CID = e.CID 
--join BackOffice.Customer f on a.CID = f.CID 
group by a.CID
;
call `dbo`.`LastRowCount`( 'final_NOP_Notional5' , V_row_count OUT

--SELECT @row_count = row_count
-- FROM sys.dm_pdw_request_steps s, sys.dm_pdw_exec_requests r
--Where r.request_id = s.request_id 
--and row_count > -1
--and r.[label] = 'final_NOP_Notional5'
--ORDER by r.[end_time] desc;
);
-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks)
IF V_RepDate>='20121231'
THEN
--drop table if exists #covarience

DROP VIEW IF EXISTS TEMP_TABLE_covarience;
-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks)
CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_covarience  
 AS
SELECT InstrumentID_a,InstrumentID_b,cast(Covariance as decimal(38,35)) as Covariance
--into #covarience
from dwh_daily_process.migration_tables.Dim_Instrument_Correlation
where DateID=CAST(date_format(DATEADD(day, -1, DATEADD(week, DATEDIFF(week, V_RepDate, 0), 0)), 'yyyyMMdd') AS int) and SampleSize>100
;
call `dbo`.`LastRowCount`( 'covarience6' , V_row_count OUT

--SELECT @row_count = row_count
-- FROM sys.dm_pdw_request_steps s, sys.dm_pdw_exec_requests r
--Where r.request_id = s.request_id 
--and row_count > -1
--and r.[label] = 'covarience6'
--ORDER by r.[end_time] desc;
);
-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks)
DROP VIEW IF EXISTS TEMP_TABLE_Equity;
-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks)
CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_Equity  
 AS
select CID,TotalPositionsAmount+TotalCash+TotalStockOrders+InProcessCashouts as Equity
---into #Equity 
FROM  dwh_daily_process.migration_tables.Fact_SnapshotEquity a 
JOIN dwh_daily_process.migration_tables.V_M2M_Date_DateRange b
ON(a.DateRangeID=b.DateRangeID) 
where b.DateKey=V_dateid 
and TotalPositionsAmount+TotalCash+TotalStockOrders+InProcessCashouts>0
;
call `dbo`.`LastRowCount`( 'Equity7' , V_row_count OUT

--SELECT @row_count = row_count
-- FROM sys.dm_pdw_request_steps s, sys.dm_pdw_exec_requests r
--Where r.request_id = s.request_id 
--and row_count > -1
--and r.[label] = 'Equity7'
--ORDER by r.[end_time] desc;


 create clustered columnstore index IX_TotalPositionsAmount on TEMP_TABLE_Equity

);
-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks)
DROP VIEW IF EXISTS TEMP_TABLE_WieghtedProtfolio;
-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks)
CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_WieghtedProtfolio  
 AS
select a.CID,a.InstrumentID,max(Equity) as Equity,
sum(AmountInUnitsDecimal*InitForexRate*(case when IsBuy='true' then 1 else -1 end)*(case when SellCurrencyID=1 then 1 
	                                                                                   when BuyCurrencyID=1 then 1/InitForexRate
																				   else LastOpConversionRate end)) /max(Equity) as Wieght
--into #WieghtedProtfolio
from TEMP_TABLE_OpenPositions a join dwh_daily_process.migration_tables.Ext_FCUPNL_Dictionary_Instrument b
on (a.InstrumentID=b.InstrumentID)
join TEMP_TABLE_Equity c
on(a.CID=c.CID)
group by a.CID,a.InstrumentID
;
call `dbo`.`LastRowCount`( 'WieghtedProtfolio8' , V_row_count OUT

--SELECT @row_count = row_count
-- FROM sys.dm_pdw_request_steps s, sys.dm_pdw_exec_requests r
--Where r.request_id = s.request_id 
--and row_count > -1
--and r.[label] = 'WieghtedProtfolio8'
--ORDER by r.[end_time] desc;


 create clustered columnstore index IX_CID on TEMP_TABLE_WieghtedProtfolio

);
-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks)
-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks)
DROP VIEW IF EXISTS TEMP_TABLE_CIDsRisk;
CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_CIDsRisk  
 AS
select a.CID,
count(distinct a.InstrumentID) as NumOfInstrumnts,
sqrt(case when sum(cast(a.Wieght as DOUBLE)*cast(b.Wieght as DOUBLE)*cast(c.Covariance as DOUBLE))<0 then 0 else sum(cast(a.Wieght as DOUBLE)*cast(b.Wieght as DOUBLE)*cast(c.Covariance as DOUBLE)) end ) as std
--into #CIDsRisk
from TEMP_TABLE_WieghtedProtfolio a join TEMP_TABLE_WieghtedProtfolio b
on(a.CID=b.CID)
left join TEMP_TABLE_covarience c
on(c.InstrumentID_a=a.InstrumentID and c.InstrumentID_b=b.InstrumentID)
group by a.CID
;
call `dbo`.`LastRowCount`( 'CIDsRisk9' , V_row_count OUT

--SELECT @row_count = row_count
-- FROM sys.dm_pdw_request_steps s, sys.dm_pdw_exec_requests r
--Where r.request_id = s.request_id 
--and row_count > -1
--and r.[label] = 'CIDsRisk9'
--ORDER by r.[end_time] desc;


 create clustered columnstore index IX_CID on TEMP_TABLE_CIDsRisk 

);
-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks) INSERT INTO dwh_daily_process.migration_tables.Fact_CustomerUnrealized_PnL (CID , DateModified , PositionPnL , PositionPnLStocksReal , PositionPnLCryptoReal , CopyPositionPnL , MenualPositionPnL , StocksPositionPnL , StandardDeviation , CommissionOnOpen , FullCommissionOnOpen , MirrorStocksPositionPnL , CryptoPositionPnL , ManualCryptoPositionPnL , CopyCryptoPositionPnL , CopyFundPnL , UpdateDate , NOP , Notional , NOP_Crypto , Notional_Crypto , NOP_CFD , Notional_CFD , NOP_Crypto_CFD , Notional_Crypto_CFD , NOP_Stock , Notional_Stock , NOP_Stock_CFD , Notional_Stock_CFD , CommissionByUnits , FullCommissionByUnits , FullCommissionByUnitsStocksReal , FullCommissionByUnitsCryptoReal , GuruCopiesPNL , GuruCopiesPNL_Dit , CommissionByUnitsStocksReal , CommissionByUnitsCryptoReal , FullCommissionByUnitsStocksCFD , FullCommissionByUnitsCryptoCFD ,CommissionByUnitsCrypto_TRS ,CopyCryptoPositionPnL_TRS ,CryptoPositionPnL_TRS ,FullCommissionByUnitsCrypto_TRS ,ManualCryptoPositionPnL_TRS ,NOP_Crypto_TRS ,Notional_Crypto_TRS ) select a.CID ,DateID ,PositionPnL ,PositionPnLStocksReal ,PositionPnLCryptoReal ,CopyPositionPnL ,MenualPositionPnL ,StocksPositionPnL ,COALESCE(b.std, 0) as StandardDeviation ,Commission ,FullCommission ,MirrorStocksPositionPnL ,CryptoPositionPnL ,ManualCryptoPositionPnL ,CopyCryptoPositionPnL ,CopyFundPnL ,current_timestamp() as UpdateDate ,NOP ,Notional ,NOP_Crypto ,Notional_Crypto ,NOP_CFD ,Notional_CFD ,NOP_Crypto_CFD ,Notional_Crypto_CFD , NOP_Stock , Notional_Stock , NOP_Stock_CFD , Notional_Stock_CFD , CommissionByUnits , FullCommissionByUnits , FullCommissionByUnitsStocksReal , FullCommissionByUnitsCryptoReal , GuruCopiesPNL , GuruCopiesPNL_Dit , CommissionByUnitsStocksReal , CommissionByUnitsCryptoReal , FullCommissionByUnitsStocksCFD , FullCommissionByUnitsCryptoCFD ,CommissionByUnitsCrypto_TRS ,CopyCryptoPositionPnL_TRS ,CryptoPositionPnL_TRS ,FullCommissionByUnitsCrypto_TRS ,ManualCryptoPositionPnL_TRS ,NOP_Crypto_TRS ,Notional_Crypto_TRS from (select CID,CAST(date_format(V_RepDate, 'yyyyMMdd') as int) as DateID ,sum(CalculatedNetProfit) as PositionPnL ,sum(case when IsSettled = 1 and InstrumentTypeID in(5,6) THEN CalculatedNetProfit ELSE 0 END ) as PositionPnLStocksReal ,sum(case when IsSettled = 1 and InstrumentTypeID in(10) THEN CalculatedNetProfit ELSE 0 END ) as PositionPnLCryptoReal ,sum(case WHEN MirrorID>0 THEN CalculatedNetProfit ELSE 0 END) as CopyPositionPnL ,sum(CASE when MirrorID=0 THEN CalculatedNetProfit ELSE 0 end) as MenualPositionPnL ,sum(case when InstrumentTypeID in(5,6) then CalculatedNetProfit else 0 end) as StocksPositionPnL ,SUM(CASE WHEN InstrumentTypeID in(5,6) AND MirrorID>0 THEN CalculatedNetProfit ELSE 0 END) AS MirrorStocksPositionPnL ,sum(Commission) as Commission ,sum(FullCommission) as FullCommission ,SUM(CASE WHEN InstrumentTypeID in(10) THEN CalculatedNetProfit ELSE 0 end) AS CryptoPositionPnL ,SUM(CASE WHEN InstrumentTypeID in(10) AND MirrorID=0 THEN CalculatedNetProfit ELSE 0 end) AS ManualCryptoPositionPnL ,SUM(CASE WHEN InstrumentTypeID in(10) AND MirrorID>0 THEN CalculatedNetProfit ELSE 0 END) AS CopyCryptoPositionPnL ,SUM(CASE WHEN CopyFund = 1 THEN CalculatedNetProfit ELSE 0 END) AS CopyFundPnL ,SUM(CommissionByUnits) as CommissionByUnits ,SUM(FullCommissionByUnits) as FullCommissionByUnits ,sum(case when IsSettled = 1 and InstrumentTypeID in(5,6) THEN FullCommissionByUnits ELSE 0 END ) as FullCommissionByUnitsStocksReal ,sum(case when IsSettled = 1 and InstrumentTypeID in(10) THEN FullCommissionByUnits ELSE 0 END ) as FullCommissionByUnitsCryptoReal ,sum(case when ConnectedGuruCopies = 1 and MirrorID>0 THEN CalculatedNetProfit ELSE 0 END ) as GuruCopiesPNL ,sum(case when ConnectedGuruCopies = 0 and MirrorID>0 THEN CalculatedNetProfit ELSE 0 END ) as GuruCopiesPNL_Dit ,sum(case when IsSettled = 1 and InstrumentTypeID in(5,6) THEN CommissionByUnits ELSE 0 END ) as CommissionByUnitsStocksReal ,sum(case when IsSettled = 1 and InstrumentTypeID in(10) THEN CommissionByUnits ELSE 0 END ) as CommissionByUnitsCryptoReal ,sum(case when IsSettled = 0 and InstrumentTypeID in(5,6) THEN FullCommissionByUnits ELSE 0 END ) as FullCommissionByUnitsStocksCFD ,sum(case when IsSettled = 0 and InstrumentTypeID in(10) THEN FullCommissionByUnits ELSE 0 END ) as FullCommissionByUnitsCryptoCFD ,sum(case when IsSettled = 0 and InstrumentTypeID in(10) and SettlementTypeID=2 THEN CommissionByUnits ELSE 0 END ) as CommissionByUnitsCrypto_TRS ,sum(case when InstrumentTypeID in(10) AND MirrorID>0 and SettlementTypeID=2 THEN CalculatedNetProfit ELSE 0 END) as CopyCryptoPositionPnL_TRS ,sum(case when InstrumentTypeID in(10) and SettlementTypeID=2 THEN CalculatedNetProfit ELSE 0 end) as CryptoPositionPnL_TRS ,sum(case when IsSettled = 0 and InstrumentTypeID in(10) and SettlementTypeID=2 THEN FullCommissionByUnits ELSE 0 END ) as FullCommissionByUnitsCrypto_TRS ,sum(case when InstrumentTypeID in(10) AND MirrorID=0 and SettlementTypeID=2 THEN CalculatedNetProfit ELSE 0 end) as ManualCryptoPositionPnL_TRS from TEMP_TABLE_UnrealizedPnL where CalculatedNetProfit is NOT null group by CID)a left join TEMP_TABLE_CIDsRisk b on(a.CID=b.CID) left join TEMP_TABLE_final_NOP_Notional n on(a.CID=n.CID)
call `dbo`.`LastRowCount`( 'Fact_CustomerUnrealized_PnL10' , V_row_count OUT

--SELECT @row_count = row_count
-- FROM sys.dm_pdw_request_steps s, sys.dm_pdw_exec_requests r
--Where r.request_id = s.request_id 
--and row_count > -1
--and r.[label] = 'Fact_CustomerUnrealized_PnL10'
--ORDER by r.[end_time] desc;
);
-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks)
-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks)
DELETE FROM dwh_daily_process.migration_tables.Fact_CustomerUnrealized_PnL_UserAPI where DateModified = V_dateid

;
INSERT INTO dwh_daily_process.migration_tables.Fact_CustomerUnrealized_PnL_UserAPI
           (`CID`
           ,`DateModified`
           ,`PositionPnL`
           ,`CopyPositionPnL`
           ,`MenualPositionPnL`
           ,`StocksPositionPnL`
           ,`UpdateDate`
           ,`TransURPnL`
           ,`StandardDeviation`
           ,`CommissionOnOpen`
           ,`MirrorStocksPositionPnL`
           ,`CryptoPositionPnL`
           ,`ManualCryptoPositionPnL`
           ,`CopyCryptoPositionPnL`
           ,`CopyFundPnL`
           ,`FullCommissionOnOpen`
           ,`NOP`
           ,`Notional`
           ,`NOP_Crypto`
           ,`Notional_Crypto`
           ,`NOP_CFD`
           ,`Notional_CFD`
           ,`NOP_Crypto_CFD`
           ,`Notional_Crypto_CFD`
           ,`CommissionByUnits`
           ,`FullCommissionByUnits`
           ,`NOP_Stock`
           ,`Notional_Stock`
           ,`NOP_Stock_CFD`
           ,`Notional_Stock_CFD`
           ,`PositionPnLStocksReal`
           ,`PositionPnLCryptoReal`
		   ,`FullCommissionByUnitsStocksReal`
		   ,`FullCommissionByUnitsCryptoReal`

	)
     SELECT
	 `CID`
           ,`DateModified`
           ,`PositionPnL`
           ,`CopyPositionPnL`
           ,`MenualPositionPnL`
           ,`StocksPositionPnL`
           ,`UpdateDate`
           ,`TransURPnL`
           ,`StandardDeviation`
           ,`CommissionOnOpen`
           ,`MirrorStocksPositionPnL`
           ,`CryptoPositionPnL`
           ,`ManualCryptoPositionPnL`
           ,`CopyCryptoPositionPnL`
           ,`CopyFundPnL`
           ,`FullCommissionOnOpen`
           ,`NOP`
           ,`Notional`
           ,`NOP_Crypto`
           ,`Notional_Crypto`
           ,`NOP_CFD`
           ,`Notional_CFD`
           ,`NOP_Crypto_CFD`
           ,`Notional_Crypto_CFD`
           ,`CommissionByUnits`
           ,`FullCommissionByUnits`
           ,`NOP_Stock`
           ,`Notional_Stock`
           ,`NOP_Stock_CFD`
           ,`Notional_Stock_CFD`
           ,`PositionPnLStocksReal`
           ,`PositionPnLCryptoReal`
		   ,`FullCommissionByUnitsStocksReal`
		   ,`FullCommissionByUnitsCryptoReal`
		   from dwh_daily_process.migration_tables.Fact_CustomerUnrealized_PnL
           WHERE DateModified = V_dateid
;
call `dbo`.`LastRowCount`( 'Fact_CustomerUnrealized_PnL_UserAPI11' , V_row_count OUT

--SELECT @row_count = row_count
-- FROM sys.dm_pdw_request_steps s, sys.dm_pdw_exec_requests r
--Where r.request_id = s.request_id 
--and row_count > -1
--and r.[label] = 'Fact_CustomerUnrealized_PnL_UserAPI11'
--ORDER by r.[end_time] desc;
);
-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks)
END IF; /*if*/
ELSE
BEGIN

-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks) INSERT INTO dwh_daily_process.migration_tables.Fact_CustomerUnrealized_PnL (CID , DateModified , PositionPnL , PositionPnLStocksReal , PositionPnLCryptoReal , CopyPositionPnL , MenualPositionPnL , StocksPositionPnL , CommissionOnOpen , FullCommissionOnOpen , MirrorStocksPositionPnL , CryptoPositionPnL , ManualCryptoPositionPnL , CopyCryptoPositionPnL , CopyFundPnL , UpdateDate , NOP , Notional , NOP_Crypto , Notional_Crypto , NOP_CFD , Notional_CFD , NOP_Crypto_CFD , Notional_Crypto_CFD , NOP_Stock , Notional_Stock , NOP_Stock_CFD , Notional_Stock_CFD , CommissionByUnits , FullCommissionByUnits , FullCommissionByUnitsStocksReal , FullCommissionByUnitsCryptoReal , GuruCopiesPNL , GuruCopiesPNL_Dit , CommissionByUnitsStocksReal , CommissionByUnitsCryptoReal , FullCommissionByUnitsStocksCFD , FullCommissionByUnitsCryptoCFD ,CommissionByUnitsCrypto_TRS ,CopyCryptoPositionPnL_TRS ,CryptoPositionPnL_TRS ,FullCommissionByUnitsCrypto_TRS ,ManualCryptoPositionPnL_TRS ,NOP_Crypto_TRS ,Notional_Crypto_TRS ) select a.CID ,DateID ,PositionPnL ,PositionPnLStocksReal ,PositionPnLCryptoReal ,CopyPositionPnL ,MenualPositionPnL ,StocksPositionPnL ,Commission ,FullCommission ,MirrorStocksPositionPnL ,CryptoPositionPnL ,ManualCryptoPositionPnL ,CopyCryptoPositionPnL ,CopyFundPnL ,current_timestamp() as UpdateDate ,NOP ,Notional ,NOP_Crypto ,Notional_Crypto ,NOP_CFD ,Notional_CFD ,NOP_Crypto_CFD ,Notional_Crypto_CFD , NOP_Stock , Notional_Stock , NOP_Stock_CFD , Notional_Stock_CFD , CommissionByUnits , `FullCommissionByUnits` , FullCommissionByUnitsStocksReal , FullCommissionByUnitsCryptoReal , GuruCopiesPNL , GuruCopiesPNL_Dit , CommissionByUnitsStocksReal , CommissionByUnitsCryptoReal , FullCommissionByUnitsStocksCFD , FullCommissionByUnitsCryptoCFD ,CommissionByUnitsCrypto_TRS ,CopyCryptoPositionPnL_TRS ,CryptoPositionPnL_TRS ,FullCommissionByUnitsCrypto_TRS ,ManualCryptoPositionPnL_TRS ,NOP_Crypto_TRS ,Notional_Crypto_TRS from (select CID,CAST(date_format(V_RepDate, 'yyyyMMdd') as int) as DateID ,sum(CalculatedNetProfit) as PositionPnL ,sum(case when IsSettled = 1 and InstrumentTypeID in(5,6) THEN CalculatedNetProfit ELSE 0 END ) as PositionPnLStocksReal ,sum(case when IsSettled = 1 and InstrumentTypeID in(10) THEN CalculatedNetProfit ELSE 0 END ) as PositionPnLCryptoReal ,sum(case WHEN MirrorID>0 THEN CalculatedNetProfit ELSE 0 END) as CopyPositionPnL ,sum(CASE when MirrorID=0 THEN CalculatedNetProfit ELSE 0 end) as MenualPositionPnL ,sum(case when InstrumentTypeID in(5,6) then CalculatedNetProfit else 0 end) as StocksPositionPnL ,SUM(CASE WHEN InstrumentTypeID in(5,6) AND MirrorID>0 THEN CalculatedNetProfit ELSE 0 END) AS MirrorStocksPositionPnL ,sum(Commission) as Commission ,sum(FullCommission) as FullCommission ,SUM(CASE WHEN InstrumentTypeID in(10) THEN CalculatedNetProfit ELSE 0 end) AS CryptoPositionPnL ,SUM(CASE WHEN InstrumentTypeID in(10) AND MirrorID=0 THEN CalculatedNetProfit ELSE 0 end) AS ManualCryptoPositionPnL ,SUM(CASE WHEN InstrumentTypeID in(10) AND MirrorID>0 THEN CalculatedNetProfit ELSE 0 END) AS CopyCryptoPositionPnL ,SUM(CASE WHEN CopyFund = 1 THEN CalculatedNetProfit ELSE 0 END) AS CopyFundPnL ,SUM(CommissionByUnits) as CommissionByUnits ,SUM(FullCommissionByUnits) as FullCommissionByUnits ,sum(case when IsSettled = 1 and InstrumentTypeID in(5,6) THEN FullCommissionByUnits ELSE 0 END ) as FullCommissionByUnitsStocksReal ,sum(case when IsSettled = 1 and InstrumentTypeID in(10) THEN FullCommissionByUnits ELSE 0 END ) as FullCommissionByUnitsCryptoReal ,sum(case when ConnectedGuruCopies = 1 and MirrorID>0 THEN CalculatedNetProfit ELSE 0 END ) as GuruCopiesPNL ,sum(case when ConnectedGuruCopies = 0 and MirrorID>0 THEN CalculatedNetProfit ELSE 0 END ) as GuruCopiesPNL_Dit ,sum(case when IsSettled = 1 and InstrumentTypeID in(5,6) THEN CommissionByUnits ELSE 0 END ) as CommissionByUnitsStocksReal ,sum(case when IsSettled = 1 and InstrumentTypeID in(10) THEN CommissionByUnits ELSE 0 END ) as CommissionByUnitsCryptoReal ,sum(case when IsSettled = 0 and InstrumentTypeID in(5,6) THEN FullCommissionByUnits ELSE 0 END ) as FullCommissionByUnitsStocksCFD ,sum(case when IsSettled = 0 and InstrumentTypeID in(10) THEN FullCommissionByUnits ELSE 0 END ) as FullCommissionByUnitsCryptoCFD ,sum(case when IsSettled = 1 and InstrumentTypeID in(10) and SettlementTypeID=2 THEN CommissionByUnits ELSE 0 END ) as CommissionByUnitsCrypto_TRS ,sum(case when InstrumentTypeID in(10) AND MirrorID>0 and SettlementTypeID=2 THEN CalculatedNetProfit ELSE 0 END) as CopyCryptoPositionPnL_TRS ,sum(case when InstrumentTypeID in(10) and SettlementTypeID=2 THEN CalculatedNetProfit ELSE 0 end) as CryptoPositionPnL_TRS ,sum(case when IsSettled = 1 and InstrumentTypeID in(10) and SettlementTypeID=2 THEN FullCommissionByUnits ELSE 0 END ) as FullCommissionByUnitsCrypto_TRS ,sum(case when InstrumentTypeID in(10) AND MirrorID=0 and SettlementTypeID=2 THEN CalculatedNetProfit ELSE 0 end) as ManualCryptoPositionPnL_TRS from TEMP_TABLE_UnrealizedPnL where CalculatedNetProfit is NOT null group by CID)a left join TEMP_TABLE_final_NOP_Notional n on(a.CID=n.CID)
call `dbo`.`LastRowCount`( 'Fact_CustomerUnrealized_PnL12' , V_row_count OUT

--SELECT @row_count = row_count
-- FROM sys.dm_pdw_request_steps s, sys.dm_pdw_exec_requests r
--Where r.request_id = s.request_id 
--and row_count > -1
--and r.[label] = 'Fact_CustomerUnrealized_PnL12'
--ORDER by r.[end_time] desc;
);
-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks)
DELETE FROM dwh_daily_process.migration_tables.Fact_CustomerUnrealized_PnL_UserAPI where DateModified = V_dateid

;
-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks)
INSERT INTO dwh_daily_process.migration_tables.Fact_CustomerUnrealized_PnL_UserAPI
           (`CID`
           ,`DateModified`
           ,`PositionPnL`
           ,`CopyPositionPnL`
           ,`MenualPositionPnL`
           ,`StocksPositionPnL`
           ,`UpdateDate`
           ,`TransURPnL`
           ,`StandardDeviation`
           ,`CommissionOnOpen`
           ,`MirrorStocksPositionPnL`
           ,`CryptoPositionPnL`
           ,`ManualCryptoPositionPnL`
           ,`CopyCryptoPositionPnL`
           ,`CopyFundPnL`
           ,`FullCommissionOnOpen`
           ,`NOP`
           ,`Notional`
           ,`NOP_Crypto`
           ,`Notional_Crypto`
           ,`NOP_CFD`
           ,`Notional_CFD`
           ,`NOP_Crypto_CFD`
           ,`Notional_Crypto_CFD`
           ,`CommissionByUnits`
           ,`FullCommissionByUnits`
           ,`NOP_Stock`
           ,`Notional_Stock`
           ,`NOP_Stock_CFD`
           ,`Notional_Stock_CFD`
           ,`PositionPnLStocksReal`
           ,`PositionPnLCryptoReal`
		   ,`FullCommissionByUnitsStocksReal`
		   ,`FullCommissionByUnitsCryptoReal`)
     SELECT
	 `CID`
           ,`DateModified`
           ,`PositionPnL`
           ,`CopyPositionPnL`
           ,`MenualPositionPnL`
           ,`StocksPositionPnL`
           ,`UpdateDate`
           ,`TransURPnL`
           ,`StandardDeviation`
           ,`CommissionOnOpen`
           ,`MirrorStocksPositionPnL`
           ,`CryptoPositionPnL`
           ,`ManualCryptoPositionPnL`
           ,`CopyCryptoPositionPnL`
           ,`CopyFundPnL`
           ,`FullCommissionOnOpen`
           ,`NOP`
           ,`Notional`
           ,`NOP_Crypto`
           ,`Notional_Crypto`
           ,`NOP_CFD`
           ,`Notional_CFD`
           ,`NOP_Crypto_CFD`
           ,`Notional_Crypto_CFD`
           ,`CommissionByUnits`
           ,`FullCommissionByUnits`
           ,`NOP_Stock`
           ,`Notional_Stock`
           ,`NOP_Stock_CFD`
           ,`Notional_Stock_CFD`
           ,`PositionPnLStocksReal`
           ,`PositionPnLCryptoReal`
		   ,`FullCommissionByUnitsStocksReal`
		   ,`FullCommissionByUnitsCryptoReal`
		   from dwh_daily_process.migration_tables.Fact_CustomerUnrealized_PnL
           WHERE DateModified = V_dateid
;
call `dbo`.`LastRowCount`( 'Fact_CustomerUnrealized_PnL_UserAPI13' , V_row_count OUT

--SELECT @row_count = row_count
-- FROM sys.dm_pdw_request_steps s, sys.dm_pdw_exec_requests r
--Where r.request_id = s.request_id 
--and row_count > -1
--and r.[label] = 'Fact_CustomerUnrealized_PnL_UserAPI13'
--ORDER by r.[end_time] desc;
);
-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks)
END;
