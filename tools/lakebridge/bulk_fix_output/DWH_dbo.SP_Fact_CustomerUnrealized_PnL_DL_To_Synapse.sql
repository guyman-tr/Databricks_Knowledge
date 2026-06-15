USE CATALOG dwh_daily_process;
USE SCHEMA migration_tables;



CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.SP_Fact_CustomerUnrealized_PnL_DL_To_Synapse(
IN V_dt TIMESTAMP)
LANGUAGE SQL
SQL SECURITY INVOKER
MODIFIES SQL DATA
AS

BEGIN


    
DECLARE V_Yesterday  TIMESTAMP;
DECLARE V_CurrentDate  TIMESTAMP;
-- =============================================
    -- Author:      <Anton Rosen>
    -- Create Date: 2021-11-23
    -- Description: SP intended to transfer data from DataLake to synapse
    -- exec [DWH_dbo].[SP_Fact_CustomerUnrealized_PnL_DL_To_Synapse] @dt='2024-01-23'
    -- =============================================
/***************************
** Change History
**************************
Date             Author       Description   
----------     ----------   ------------------------------------
03/02/2022      Inbal BML     add SettlementTypeID
2023-12-17      Katy F        Remove null from "NULL as InitConversionRate" for HistoryPosition
2024-01-01		Merav H		  Replace PositionChangeLog_Active 
2024-01-14		Katy F		  Add PnLVersion to Position Extracts
2024-01-24	    Inbal BML	  change [DWH_staging].[etoro_Trade_Position] to [DWH_staging].[etoro_Trade_OpenPositionEndOfDay] and [DWH_staging].[etoro_History_Position] to [DWH_staging].[etoro_History_ClosePositionEndOfDay]
							 & Add PnLInDollars and EndOfDayPnLInDollars 
2026-01-04		Eitan Lipo	  Remove For New Engine Instrument Corralation 
**********************************************************************************************************************/
    --DECLARE @dt AS DATE = '2024-01-23';

SET V_Yesterday = CAST(V_dt AS TIMESTAMP);
SET V_CurrentDate = DATEADD(DAY, 1, V_Yesterday);
--------------------------------------------------------------------
    -- Ext_FCUPNL_History_SplitRatio -----------------------------------

TRUNCATE TABLE dwh_daily_process.migration_tables.Ext_FCUPNL_History_SplitRatio;
    INSERT INTO dwh_daily_process.migration_tables.Ext_FCUPNL_History_SplitRatio
    (
        `ID`,
        `InstrumentID`,
        `MinDate`,
        `MaxDate`,
        `PriceRatio`,
        `AmountRatio`,
        `IsCompletedOpenPositions`,
        `IsCompletedClosePositions`,
        `IsCompletedOpenOrders`,
        `IsCompletedCloseOrders`,
        `PriceRatioUnAdjusted`,
        `AmountRatioUnAdjusted`,
        `IsNotificationSent`,
        `IsCurrencyPriceChanged`,
        `IsRedisUpdated`,
        `IsNotificationStartSent`,
        `IsCompletedPricAndAmount`,
        `IsCompletedModifyPrice`,
        `IsCompleteHoldingFees`
    )
    SELECT `ID`,
           `InstrumentID`,
           `MinDate`,
           `MaxDate`,
           `PriceRatio`,
           `AmountRatio`,
           `IsCompletedOpenPositions`,
           `IsCompletedClosePositions`,
           `IsCompletedOpenOrders`,
           `IsCompletedCloseOrders`,
           `PriceRatioUnAdjusted`,
           `AmountRatioUnAdjusted`,
           `IsNotificationSent`,
           `IsCurrencyPriceChanged`,
           `IsRedisUpdated`,
           `IsNotificationStartSent`,
           `IsCompletedPricAndAmount`,
           `IsCompletedModifyPrice`,
           `IsCompleteHoldingFees`
    FROM dwh_daily_process.daily_snapshot.etoro_History_SplitRatio;
--------------------------------------------------------------------
    -- Ext_FCUPNL_BackOfficeCustomer -----------------------------------

TRUNCATE TABLE dwh_daily_process.migration_tables.Ext_FCUPNL_BackOfficeCustomer;
    INSERT INTO dwh_daily_process.migration_tables.Ext_FCUPNL_BackOfficeCustomer
    (
        `rank`,
        `CID`,
        `AccountTypeID`,
        `ValidFrom`,
        `ValidTo`
    )
    SELECT ROW_NUMBER() OVER (PARTITION BY a.CID ORDER BY ValidFrom, ValidTo) rank,
           a.CID,
           a.AccountTypeID,
           a.ValidFrom,
           a.ValidTo
    FROM dwh_daily_process.daily_snapshot.etoro_History_BackOfficeCustomer a
        JOIN
        (
            SELECT DISTINCT
                   CID
            FROM dwh_daily_process.daily_snapshot.etoro_History_BackOfficeCustomer
            WHERE AccountTypeID = 9
        ) b
            ON a.CID = b.CID;
--------------------------------------------------------------------
-- Ext_FCUPNL_GetSpreadedPriceCandle60MinSplitted ------------------
/* Eitan lipovetsky - 04-01-2026 - Remove for New Engine Instrument corralition 
truncate table [DWH_dbo].[Ext_FCUPNL_GetSpreadedPriceCandle60MinSplitted]
insert into [DWH_dbo].[Ext_FCUPNL_GetSpreadedPriceCandle60MinSplitted] ([rn]
      ,[InstrumentID]
      ,[AskLast]
      ,[BidLast]
      ,[AskFirst]
      ,[DateFrom])
SELECT row_number() OVER (PARTITION BY InstrumentID ORDER BY DateFrom DESC) rn
	, InstrumentID
	, cast(AskLast as decimal (16,8)) AskLast
	, cast(BidLast as decimal (16,8)) BidLast
	, cast(AskFirst as decimal (16,8)) AskFirst
	, DateFrom 
FROM [DWH_staging].[PriceLog_Candles_GetSpreadedPriceCandle60MinSplitted] WITH (NOLOCK)
where DateFrom < @Yesterday
*/
----------------------------------------------------------------------
---- Ext_FCUPNL_Dictionary_Instrument --------------------------------

TRUNCATE table  dwh_daily_process.migration_tables.Ext_FCUPNL_Dictionary_Instrument;
insert into  dwh_daily_process.migration_tables.Ext_FCUPNL_Dictionary_Instrument 
( `InstrumentID`
      ,`BuyCurrencyID`
      ,`SellCurrencyID`
      ,`InstrumentTypeID`
      ,`Name`
      ,`TradeRange`
      ,`DollarRatio`
      --,[Passport]
      ,`PipDifferenceThreshold`
      ,`IsMajor`
      --,[Industry]
      --,[ExchangeID]
	  )
SELECT  `InstrumentID`
      ,`BuyCurrencyID`
      ,`SellCurrencyID`
      ,`InstrumentTypeID`
      ,`Name`
      ,`TradeRange`
      ,`DollarRatio`
      --,[Passport]
      ,`PipDifferenceThreshold`
      ,`IsMajor`
      --,[Industry]
      --,[ExchangeID]
  FROM dwh_daily_process.daily_snapshot.etoro_Trade_GetInstrument;
----------------------------------------------------------------------
---- Ext_FCUPNL_History_Mirror ---------------------------------------
TRUNCATE table dwh_daily_process.migration_tables.Ext_FCUPNL_History_Mirror;
insert into dwh_daily_process.migration_tables.Ext_FCUPNL_History_Mirror 
(`ID`
      ,`MirrorID`
      ,`CID`
      ,`ParentCID`
      ,`ParentUserName`
      ,`Amount`
      ,`Occurred`
      ,`IsActive`
      ,`ModificationDate`
      ,`MirrorOperationID`
      ,`MirrorTypeID`
      ,`IsOpenOpen`
      ,`GuruTPV`
      ,`MirrorSL`
      ,`CloseMirrorActionType`
      ,`RealizedEquity`
      ,`PauseCopy`
      ,`MirrorSLPercentage`
      ,`InitialInvestment`
      ,`DepositSummary`
      ,`WithdrawalSummary`
      ,`SessionID`
      ,`NetProfit`
      ,`UseCopyDividend`
      ,`MIMOOperationTypeID`
      ,`MirrorDividendID`)

select `ID`
      ,`MirrorID`
      ,`CID`
      ,`ParentCID`
      ,`ParentUserName`
      ,`Amount`
      ,`Occurred`
      ,`CAST(IsActive AS INT)`
      ,`ModificationDate`
      ,`MirrorOperationID`
      ,`MirrorTypeID`
      ,`IsOpenOpen`
      ,`GuruTPV`
      ,`MirrorSL`
      ,`CloseMirrorActionType`
      ,`RealizedEquity`
      ,`PauseCopy`
      ,`MirrorSLPercentage`
      ,`InitialInvestment`
      ,`DepositSummary`
      ,`WithdrawalSummary`
      ,`SessionID`
      ,`NetProfit`
      ,`UseCopyDividend`
      ,`MIMOOperationTypeID`
      ,`MirrorDividendID`
from  dwh_daily_process.daily_snapshot.etoro_History_Mirror 
where MirrorOperationID = 1;
---------------------------------------------------------------------
---- Ext_FSE_History_Position ---------------------------------------
TRUNCATE table dwh_daily_process.migration_tables.Ext_FCUPNL_History_Position ;
insert into dwh_daily_process.migration_tables.Ext_FCUPNL_History_Position 
( PositionID
, CID
, MirrorID
,InstrumentID
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
,IsSettled
,CommissionByUnits
,FullCommissionByUnits
,IsDiscounted
,OriginalPositionID
, InitConversionRate
, InitConversionRateID
, ParentPositionID
, SettlementTypeID
,PnLVersion
,EndOfDayPnLInDollars )
SELECT 
  PositionID
, CID
, MirrorID
,a.InstrumentID
, OpenOccurred
, CloseOccurred
, nullif(AmountInUnitsDecimal,0) as AmountInUnitsDecimal
, InitForexRate
, SpreadedPipBid
, SpreadedPipAsk
, IsBuy
, LastOpConversionRate
, Commission
, FullCommission
,case 
when CAST(IsSettled AS INT) in (1,0) then cast(IsSettled as int)  
when IsBuy = 1 And Leverage = 1 and b.InstrumentTypeID in (10,5,6) then 1 
else 0 
end as IsSettled
,CommissionByUnits
,FullCommissionByUnits
,cast(IsDiscounted as int) as IsDiscounted
,OriginalPositionID
,InitConversionRate -- KF 20231217
,InitConversionRateID -- KF 20231217
, ParentPositionID
, SettlementTypeID
, PnLVersion
, EndOfDayPnLInDollars
FROM dwh_daily_process.daily_snapshot.etoro_History_ClosePositionEndOfDay a  
left join dwh_daily_process.daily_snapshot.etoro_Trade_GetInstrument b
on a.InstrumentID = b.InstrumentID
Where
OpenOccurred < V_CurrentDate
		AND CloseOccurred >=  V_CurrentDate 
;
-- [stub] WITH FULLSCAN -- Synapse stats hint, no-op in Databricks
----------------------------------------------------------------------
---- Ext_FCUPNL_Trade_Position ---------------------------------------
TRUNCATE table dwh_daily_process.migration_tables.Ext_FCUPNL_Trade_Position;
insert into dwh_daily_process.migration_tables.Ext_FCUPNL_Trade_Position
(`PositionID`
      ,`CID`
      ,`MirrorID`
      ,`InstrumentID`
      ,`OpenOccurred`
      ,`CloseOccurred`
      ,`AmountInUnitsDecimal`
      ,`InitForexRate`
      ,`SpreadedPipBid`
      ,`SpreadedPipAsk`
      ,`IsBuy`
      ,`LastOpConversionRate`
      ,`Commission`
      ,`FullCommission`
      ,`IsSettled`
      ,`CommissionByUnits`
      ,`FullCommissionByUnits`
      ,`IsDiscounted`
      ,`InitConversionRate`
      ,`InitConversionRateID`
      ,`ParentPositionID`
	  ,`SettlementTypeID`
	  ,PnLVersion
	  ,PnLInDollars  
	   )

SELECT 
  PositionID
, CID
, MirrorID
, a.InstrumentID
, Occurred as OpenOccurred
, NULL as CloseOccurred
, nullif(AmountInUnitsDecimal,0) as AmountInUnitsDecimal
, InitForexRate
, SpreadedPipBid
, SpreadedPipAsk
, IsBuy
, LastOpConversionRate
, Commission
, FullCommission
,case 
when CAST(IsSettled AS INT) in (1,0) then cast(IsSettled as int)  
when IsBuy = 1 And Leverage = 1 and b.InstrumentTypeID in (10,5,6) then 1 
else 0 
end as IsSettled
      ,`CommissionByUnits`
      ,`FullCommissionByUnits`
,cast(IsDiscounted as int) as IsDiscounted
,InitConversionRate
,InitConversionRateID
, ParentPositionID
, SettlementTypeID
,PnLVersion
,PnLInDollars  
FROM   dwh_daily_process.daily_snapshot.etoro_Trade_OpenPositionEndOfDay a  
left join dwh_daily_process.daily_snapshot.etoro_Trade_GetInstrument b
on a.InstrumentID = b.InstrumentID
	WHERE  Occurred< V_CurrentDate;

----------------------------------------------------------------------
---- Ext_FCUPNL_PositionChangeLog ---------------------------------------
TRUNCATE table  dwh_daily_process.migration_tables.Ext_FCUPNL_PositionChangeLog;
insert into dwh_daily_process.migration_tables.Ext_FCUPNL_PositionChangeLog 
(`PositionID`
      ,`CID`
      ,`Occurred`
      ,`IsSettled`
      ,`PreviousIsSettled`)
select 
PositionID,
CID,
Occurred,
COALESCE(Cast(IsSettled as int), 0) IsSettled,
COALESCE(cast(PreviousIsSettled as int ), 0) PreviousIsSettled
from
(
select
pl.PositionID
,pl.CID
,Occurred
,CAST(pl.IsSettled AS INT)
,CAST(pl.PreviousIsSettled AS INT)
, ROW_NUMBER() over (partition by pl.PositionID order by  pl.Occurred ) rn
from dwh_daily_process.daily_snapshot.etoro_History_PositionChangeLog pl 
where Occurred > V_CurrentDate
---and isnull(CAST(pl.IsSettled AS INT),-1) <> isnull(CAST(pl.PreviousIsSettled AS INT),-1)
and COALESCE(Cast(pl.IsSettled  as int), 0)<> COALESCE(cast( pl.PreviousIsSettled as int), 0)
) a
where rn =1;
-- [stub] WITH FULLSCAN -- Synapse stats hint, no-op in Databricks
----------------------------------------------------------------------
---- Ext_FCA_Real_Audit_Loggin ---------------------------------------
TRUNCATE table dwh_daily_process.migration_tables.Ext_FCUPNL_CurrencyPriceMaxDateWithSplit;
insert into dwh_daily_process.migration_tables.Ext_FCUPNL_CurrencyPriceMaxDateWithSplit 
(`ProviderID`
      ,`InstrumentID`
      ,`Occurred`
      ,`OccurredDate`
      ,`OccurredDateID`
      ,`isvalid`
      ,`AskSpreaded`
      ,`BidSpreaded`
      ,`RateLastEx`
      ,`Ask`
      ,`Bid`
      ,`UpdateDate`)
SELECT
`ProviderID`
      ,`InstrumentID`
      ,`Occurred`
      ,`OccurredDate`
      ,`OccurredDateID`
      ,`isvalid`
      ,`AskSpreaded`
      ,`BidSpreaded`
      ,`RateLastEx`
      ,`Ask`
      ,`Bid`
,current_timestamp() as UpdateDate
 FROM dwh_daily_process.daily_snapshot.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView
where OccurredDate = V_Yesterday;

-- Eitan Lipovetsky  - Remove for engine instrument corralation 
--EXEC [DWH_dbo].[SP_Dim_Instrument_Correlation] @dt 
call dwh_daily_process.migration_tables.SP_Fact_CustomerUnrealized_PnL(V_dt);
END;
