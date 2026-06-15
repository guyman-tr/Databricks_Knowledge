USE CATALOG dwh_daily_process;
USE SCHEMA migration_tables;



CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.SP_Dim_Position_DL_To_Synapse_bkp_2024_08_04(
IN V_dt TIMESTAMP)
LANGUAGE SQL
SQL SECURITY INVOKER
MODIFIES SQL DATA
AS


BEGIN



DECLARE V_CurrentDate  TIMESTAMP
;
DECLARE V_Yesterday  TIMESTAMP
;
DECLARE V_upsts STRING;
-- =============================================
-- Author:      <Re'em Cohen>
-- Create Date: 2021-07-27
-- Description: SP intended to transfer data from DataLake to synapse
-- exec [DWH_dbo].[SP_Dim_Position_DL_To_Synapse] '20240123'
-- =============================================
/***************************
** Change History
**************************
Date           Author        Description   
----------     ----------    ------------------------------------
01/02/2022     Inbal BML      add SettlementTypeID
14/04/2022	   Inbal BML	  add OpenMarketPriceRateID
2022-05-14     Boris Slutski  change caluclation VolumeonClose for closed Position --> Cast([AmountInUnitsDecimal]as Float)
2022-07-03     Boris Slutski  add condition to Merge script
2023-03-07     nir harari     add 12 column OpenMarket*,CloseMarket* ,CloseMarketCoversionRateBidSpreaded ,CloseMarketCoversionRateAskSpreaded 
2023-05-22     nir harari     add 3 columns RequestOpenOccurred,RequestCloseOccurred ,OrderType 
2023-06-14     nir harari     change update for dim position
2024-01-03     KatyF          Add PnLVersion & Fill InitConversionRate. Remove hardcoded NULL for InitConversionRate in ext
2024-01-15	   Inbal BML	  change [DWH_staging].[etoro_Trade_Position] to [DWH_staging].[etoro_Trade_OpenPositionEndOfDay] and [DWH_staging].[etoro_History_Position] to [DWH_staging].[etoro_History_ClosePositionEndOfDay]
							  & Add PnLInDollars , EndOfDayPnLInDollars ,  OpenMarketSpread , CloseMarketSpread , CloseMarkupOnOpen , OpenMarkup and CloseMarkup
2024-03-10	   Daniel K	      add exec [DWH_dbo].[SP_Check_PnLInDollars_in_DWH_staging_etoro_Trade_OpenPositionEndOfDay] 

--**********************************************************************************************************************/
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    
--DECLARE @dt Date ='2024-01-23'  

SET V_Yesterday = CAST(V_dt as TIMESTAMP);
SET V_CurrentDate = DATEADD(DAY, 1, V_Yesterday);
call dwh_daily_process.migration_tables.SP_Check_PnLInDollars_in_DWH_staging_etoro_Trade_OpenPositionEndOfDay();
	DELETE FROM dwh_daily_process.migration_tables.Dim_Position 
	WHERE (OpenDateID >=  CAST(date_format(V_Yesterday, 'yyyyMMdd') AS INT)
	AND OpenDateID <  CAST(date_format(V_CurrentDate, 'yyyyMMdd') AS INT) )
	OR( CloseDateID >= CAST(date_format(V_Yesterday, 'yyyyMMdd') AS INT) AND CloseDateID < CAST(date_format(V_CurrentDate, 'yyyyMMdd') AS INT) AND PositionID<> OriginalPositionID)
;
	UPDATE dwh_daily_process.migration_tables.Dim_Position;
	set 
	CloseOccurred = '1900-01-01 00:00:00.000' ,
	CloseDateID = 19000101
	where CloseDateID >= cast(date_format(V_Yesterday, 'yyyyMMdd') AS INT) AND CloseDateID < cast(date_format(V_CurrentDate, 'yyyyMMdd') AS INT);
	
	----------------------------------------------------------------->

-- Update Dim_Position_Real --------------------------------------->
TRUNCATE TABLE dwh_daily_process.migration_tables.Ext_Dim_Position_Real

	;
-- [stub] Synapse IF EXISTS(sys.*) ... DROP elided -- UC has no sys.* catalog

-- [stub] Synapse IF EXISTS(sys.*) ... DROP elided -- UC has no sys.* catalog

----------------------------------------------------------------->

DROP VIEW IF EXISTS TEMP_TABLE_etoro_History_BackOfficeCustomer;

CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_etoro_History_BackOfficeCustomer AS
Select  *
  -- Move duplicates rows, because two parquet files with another dates
from
(
select
CID,
RegulationID,
ValidFrom,
ValidTo,
CustomerHistoryID,
ROW_NUMBER() over (partition by a.CID, CustomerHistoryID  order by a.ValidTo ) as rn
from dwh_daily_process.daily_snapshot.etoro_History_BackOfficeCustomer a 
) a
where  rn =1;

--------------------
-- Extract Ext_Dim_Position_Real --------------------------------------->
	INSERT INTO dwh_daily_process.migration_tables.Ext_Dim_Position_Real
           ( `PositionID`
           , `CID`
           , `CurrencyID`
           , `ProviderID`
           , `InstrumentID`
           , `HedgeID`
           , `HedgeServerID`
           , `Leverage`
           , `Amount`
           , `AmountInUnitsDecimal`
           , `UnitMargin`
           , `InitForexRate`
           , `NetProfit`
           , `SpreadedPipBid`
           , `SpreadedPipAsk`
           , `IsBuy`
           , `CloseOnEndOfWeek`
           , `EndOfWeekFee`
           , `Commission`
           , `CommissionOnClose`
           , `OpenOccurred`
           , `CloseOccurred`
           , `ParentPositionID`
           , `OrigParentPositionID`
           , `MirrorID`
           , `IsOpenOpen`
           , `OpenDateID`
           , `CloseDateID`
           , `LotCountDecimal`
           , `SpreadedCommission`
           , `EndForexRate`
           , `LastOpConversionRate`
           , `LimitRate`
           , `StopRate`
           , `ClosePositionReasonID`
           , `TreeID`
           , `FullCommission`
           , `FullCommissionOnClose`
           , `IsComputeForHedge`
           , `IsSettled`
           , `InitialAmountCents`
           , `RedeemStatus`
           , `RedeemID`
           , `ReopenForPositionID`
           , `IsReOpen`
           , `CommissionOnCloseOrig`
           , `FullCommissionOnCloseOrig`
           , `InitialUnits`
           , `IsDiscounted`
           , `CommissionByUnits`
           , `FullCommissionByUnits`
           , `Volume`
           , `VolumeOnClose`
           , `LastOpPriceRateID`
           , `InitForexPriceRateID`
           , `InitExecutionID`
           , `InitConversionRate`
           , `InitConversionRateID`
           , `OrderID`
           , `RegulationID`
           , `UpdateDate`
		   , `SettlementTypeID`
		   , OpenMarketPriceRateID
		   , RequestOccurred
		   , OrderType
		   , `PnLVersion` -- 20240103 KatyF
		   , PnLInDollars  --20240115 Inbal BML
		   , OpenMarketSpread --20240115 Inbal BML
		   , CloseMarkupOnOpen --20240115 Inbal BML
		   , OpenMarkup --20240115 Inbal BML

		   
		   )
		
		SELECT 
		     PositionID
		   , a.CID
		   , CurrencyID
		   , ProviderID
		   , a.InstrumentID
		   , HedgeID
		   , HedgeServerID
		   , Leverage
		   , Amount
		   , AmountInUnitsDecimal
		   , UnitMargin
		   , InitForexRate
		   , NetProfit
		   , SpreadedPipBid
		   , SpreadedPipAsk
		   , IsBuy
		   , COALESCE(CAST(CloseOnEndOfWeek AS BOOLEAN), FALSE) as CloseOnEndOfWeek
		   , EndOfWeekFee
		   , Commission
		   , 0 as CommissionOnClose
		   , Occurred as OpenOccurred
		   , CAST(0 as TIMESTAMP) as CloseOccurred
		   , ParentPositionID
		   , OrigParentPositionID
		   , MirrorID
		   , IsOpenOpen
		   , CAST(date_format(DATEADD(DAY, DATEDIFF(0, Occurred), 0), 'yyyyMMdd') AS int) as OpenDateID
		   , 0 as CloseDateID
		   , LotCountDecimal
		   , SpreadedCommission
		   , Null as EndForexRate
		   , LastOpConversionRate
		   , LimitRate
		   , StopRate
		   , Null as ClosePositionReasonID
		   , TreeID
		   , FullCommission
		   , NULL as FullCommissionOnClose
		   , IsComputeForHedge
		   , CASE 
		     WHEN CAST(IsSettled AS INT) in (1,0) THEN CAST(IsSettled as int)  
		     WHEN IsBuy = 1 AND Leverage = 1 AND b.InstrumentTypeID in (10,5,6) THEN 1 
		     ELSE 0 
		     END as IsSettled
		   , InitialAmountCents
		   , RedeemStatus
		   , NULL as RedeemID
		   , ReopenForPositionID
		   , CASE WHEN ReopenForPositionID is not null THEN 1 END as IsReOpen
		   , 0.00 as CommissionOnCloseOrig
		   , 0.00 as FullCommissionOnCloseOrig
		   , InitialUnits
		   , CAST(IsDiscounted as int)   IsDiscounted
		   , CommissionByUnits
		   , `FullCommissionByUnits`
		   , TRY_CAST(ROUND(Cast(`AmountInUnitsDecimal`as decimal(16,6))*Cast(`InitForexRate` as decimal(16,8))*
(CASE WHEN SellCurrencyID=1 THEN 1 WHEN BuyCurrencyID=1 THEN 1/cast(`InitForexRate` as decimal (16,8)) else cast(`LastOpConversionRate` as decimal (16,8)) end),0) AS int)  Volume
		   , 0 as VolumeOnClose
		   , LastOpPriceRateID
		   , InitForexPriceRateID
		   , InitExecutionID
		   , InitConversionRate
		   , InitConversionRateID
		   , OrderID
		   , COALESCE(c.RegulationID, 0) as RegulationID
		   , current_timestamp() as UpdateDate
		   , SettlementTypeID
		   , OpenMarketPriceRateID
		   , RequestOccurred
		   , OrderType
		   , COALESCE(PnLVersion, 0) AS PnLVersion  -- 20240103 KatyF
		   , PnLInDollars  --20240115 Inbal BML
		   , OpenMarketSpread --20240115 Inbal BML
		   , CloseMarkupOnOpen --20240115 Inbal BML
		   , OpenMarkup --20240115 Inbal BML
		From dwh_daily_process.daily_snapshot.etoro_Trade_OpenPositionEndOfDay a 
		left join dwh_daily_process.daily_snapshot.etoro_Trade_GetInstrument b
		on a.InstrumentID = b.InstrumentID
		left join TEMP_TABLE_etoro_History_BackOfficeCustomer c 
		--[DWH_staging].[etoro_History_BackOfficeCustomer] c with (nolock)
		ON a.CID = c.CID
		AND c.ValidFrom < V_CurrentDate
		--dateadd(day,datediff(day,-1,?),0)
		AND c.ValidTo >= V_CurrentDate
		--dateadd(day,datediff(day,-1,?),0)
		WHERE a.Occurred< V_CurrentDate;
		--dateadd(day,1,?)

----------------------------------------------------------------->

-- CREATE INDEX Ext_Dim_Position_Real --------------------------------------->
TRUNCATE TABLE dwh_daily_process.migration_tables.Ext_Dim_Position_History_Real;
----------------------------------------------------------------->

-- DROP INDEX Ext_Dim_Position_History_Real ---------------------->
IF EXISTS (SELECT Name FROM sys.indexes WHERE object_id = NULL
	AND Name = 'CL_IX_Ext_Dim_Position_History_Real_OpenDateID') 
	;
DROP INDEX CL_IX_Ext_Dim_Position_History_Real_OpenDateID ON dwh_daily_process.migration_tables.Ext_Dim_Position_History_Real;

----------------------------------------------------------------->

-- Extract Ext_Dim_Position_History_Real ------------------------>
	INSERT INTO dwh_daily_process.migration_tables.Ext_Dim_Position_History_Real
           (`PositionID`
           ,`CID`
           ,`CurrencyID`
           ,`ProviderID`
           ,`InstrumentID`
           ,`HedgeID`
           ,`HedgeServerID`
           ,`Leverage`
           ,`Amount`
           ,`AmountInUnitsDecimal`
           ,`UnitMargin`
           ,`InitForexRate`
           ,`NetProfit`
           ,`SpreadedPipBid`
           ,`SpreadedPipAsk`
           ,`IsBuy`
           ,`CloseOnEndOfWeek`
           ,`EndOfWeekFee`
           ,`Commission`
           ,`CommissionOnClose`
           ,`OpenOccurred`
           ,`CloseOccurred`
           ,`ParentPositionID`
           ,`OrigParentPositionID`
           ,`MirrorID`
           ,`IsOpenOpen`
           ,`OpenDateID`
           ,`CloseDateID`
           ,`LotCountDecimal`
           ,`SpreadedCommission`
           ,`EndForexRate`
           ,`LastOpConversionRate`
           ,`LimitRate`
           ,`StopRate`
           ,`ClosePositionReasonID`
           ,`TreeID`
           ,`FullCommission`
           ,`FullCommissionOnClose`
           ,`IsComputeForHedge`
           ,`IsSettled`
           ,`InitialAmountCents`
           ,`RedeemStatus`
           ,`RedeemID`
           ,`ReopenForPositionID`
           ,`IsReOpen`
           ,`CommissionOnCloseOrig`
           ,`FullCommissionOnCloseOrig`
		   ,`OriginalPositionID`
           ,`InitialUnits`
           ,`IsDiscounted`
           ,`CommissionByUnits`
           ,`FullCommissionByUnits`
           ,`Volume`
           ,`VolumeOnClose`
           ,`LastOpPriceRateID`
           ,`InitForexPriceRateID`
		   ,`EndForexPriceRateID`
           ,`InitExecutionID`
		   ,`EndExecutionID`
		   ,`CloseMarketPriceRateID`
           ,`InitConversionRate`
           ,`InitConversionRateID`
           ,`OrderID`
		   ,`ExitOrderID`
		   ,`RegulationID`
		   ,`LastOpPriceRate`
           ,`UpdateDate`
		   ,`SettlementTypeID`
		   ,OpenMarketPriceRateID
		   ,RequestOpenOccurred
		   ,RequestCloseOccurred
		   ,OrderType
		   ,`PnLVersion`
		   ,EndOfDayPnLInDollars -- 20240115 Inbal BML
		   ,OpenMarketSpread --20240115 Inbal BML
		   ,CloseMarketSpread --20240115 Inbal BML
		   ,CloseMarkupOnOpen --20240115 Inbal BML
		   ,OpenMarkup --20240115 Inbal BML
		   ,CloseMarkup --20240115 Inbal BML
			)

		SELECT
		     PositionID
		   , a.CID
		   , CurrencyID
		   , ProviderID
		   , a.InstrumentID
		   , HedgeID
		   , HedgeServerID
		   , Leverage
		   , Amount
		   , AmountInUnitsDecimal
		   , UnitMargin
		   , InitForexRate
		   , NetProfit
		   , SpreadedPipBid
		   , SpreadedPipAsk
		   , IsBuy
		   , CloseOnEndOfWeek
		   , EndOfWeekFee
		   , Commission
		   , CommissionOnClose
		   , OpenOccurred
		   , CloseOccurred
		   , ParentPositionID
		   , OrigParentPositionID
		   , MirrorID
		   , IsOpenOpen
		   , CAST(date_format(DATEADD(DAY, DATEDIFF(0, OpenOccurred), 0), 'yyyyMMdd') AS int) as OpenDateID
		   , CAST(date_format(DATEADD(DAY, DATEDIFF(0, CloseOccurred), 0), 'yyyyMMdd') AS int) as CloseDateID
		   , LotCountDecimal
		   , SpreadedCommission
		   , EndForexRate
		   , LastOpConversionRate
		   , LimitRate
		   , StopRate
		   , ActionType as ClosePositionReasonID
		   , TreeID
		   , COALESCE(FullCommission, 0.00) FullCommission
		   , COALESCE(FullCommissionOnClose, 0.00) FullCommissionOnClose
		   , IsComputeForHedge
		   , CASE 
		     WHEN CAST(IsSettled AS INT) in (1,0) THEN cast(IsSettled as int)  
		     WHEN IsBuy = 1 AND Leverage = 1 AND b.InstrumentTypeID in (10,5,6) THEN 1 
		     ELSE 0 
		     END as IsSettled
		   , InitialAmountCents
		   , RedeemStatus
		   , RedeemID
		   , ReopenForPositionID
		   , CASE WHEN ReopenForPositionID is not null THEN 1 ELSE 0 END as IsReOpen
		   , CASE WHEN ReopenForPositionID is not null THEN CommissionOnClose ELSE 0 END AS CommissionOnCloseOrig
		   , CASE WHEN ReopenForPositionID is not null THEN FullCommissionOnClose ELSE 0 END AS FullCommissionOnCloseOrig
		   , OriginalPositionID
		   , InitialUnits
		   , CAST(IsDiscounted as int)   IsDiscounted
		   , CommissionByUnits
		   , FullCommissionByUnits
		   , TRY_CAST(ROUND(Cast(`AmountInUnitsDecimal`as decimal(16,6))*Cast(`InitForexRate` as decimal(16,8))*
(CASE WHEN SellCurrencyID=1 THEN 1 WHEN BuyCurrencyID=1 THEN 1/cast(`InitForexRate` as decimal (16,8)) else cast(`LastOpConversionRate` as decimal (16,8)) end),0) AS int)  Volume
		   --,try_convert(int,ROUND(Cast([AmountInUnitsDecimal]as decimal(16,6))*Cast([InitForexRate] as decimal(16,8))*
		   --(CASE WHEN SellCurrencyID=1 THEN 1 WHEN BuyCurrencyID=1 THEN 1/cast(EndForexRate as decimal (16,8)) else cast([LastOpConversionRate] as decimal (16,8)) end),0))VolumeOnClose
		   ---,try_convert(int,ROUND(Cast([AmountInUnitsDecimal]as Float)*EndForexRate*(case when SellCurrencyID=1 then 1 when BuyCurrencyID=1 then 1/EndForexRate else LastOpConversionRate end),0)) VolumeOnClose  -- Not samr to DWH-01
		   , TRY_CAST(ROUND(`AmountInUnitsDecimal`*EndForexRate*(case when SellCurrencyID=1 then 1 when BuyCurrencyID=1 then 1/EndForexRate else LastOpConversionRate end),0) AS int) VolumeOnClose
		   , LastOpPriceRateID
		   , InitForexPriceRateID
		   , EndForexPriceRateID
		   , `InitExecutionID`
		   , `EndExecutionID` 
		   , CloseMarketPriceRateID
		   , InitConversionRate  -- 20240103 KatyF
		   , InitConversionRateID  -- 20240103 KatyF
		   , OrderID
		   , ExitOrderID
		   , COALESCE(c.RegulationID, 0) AS RegulationID
		   , LastOpPriceRate
		   , current_timestamp() AS UpdateDate
		   , SettlementTypeID
		   , OpenMarketPriceRateID
		   , RequestOpenOccurred
		   , RequestCloseOccurred
		   , OrderType
		   , COALESCE(`PnLVersion`, 0) AS `PnLVersion`  -- 20240103 KatyF
		   , EndOfDayPnLInDollars -- 20240115 Inbal BML
		   , OpenMarketSpread --20240115 Inbal BML
		   , CloseMarketSpread --20240115 Inbal BML
		   , CloseMarkupOnOpen --20240115 Inbal BML
		   , OpenMarkup --20240115 Inbal BML
		   , CloseMarkup --20240115 Inbal BML
		FROM dwh_daily_process.daily_snapshot.etoro_History_ClosePositionEndOfDay a    
		
		left join dwh_daily_process.daily_snapshot.etoro_Trade_GetInstrument b
		on a.InstrumentID = b.InstrumentID
		left join TEMP_TABLE_etoro_History_BackOfficeCustomer c 
		--[DWH_staging].[etoro_History_BackOfficeCustomer]  c with (nolock)
		ON a.CID = c.CID
		AND c.ValidFrom < V_CurrentDate
		--dateadd(day,datediff(day,-1,?),0) 
		AND c.ValidTo >= V_CurrentDate
		--dateadd(day,datediff(day,-1,?),0)
		
		WHERE
		(
			(
			 CloseOccurred >= V_Yesterday
			 AND 
			 CloseOccurred <V_CurrentDate
			 --dateadd(day,datediff(day,-1,?),0)
			)
		or
			(
			 OpenOccurred >= V_Yesterday
			 AND
			 OpenOccurred < V_CurrentDate
			 --dateadd(day,datediff(day,-1,?),0)
			 AND
			 CloseOccurred > V_Yesterday
			)
		or
			(
			OpenOccurred < V_CurrentDate
			--dateadd(day,datediff(day,-1,?),0)
			AND
			CloseOccurred >= V_Yesterday
			)
		);
		--OPTION	(RECOMPILE)

----------------------------------------------------------------->

-- CREATE INDEX Ext_Dim_Position_History_Real ------------------->
TRUNCATE TABLE dwh_daily_process.migration_tables.Ext_Dim_Position_PositionChangeLog

;
	INSERT INTO dwh_daily_process.migration_tables.Ext_Dim_Position_PositionChangeLog
		SELECT
		PositionID,
		CID,
		Occurred,
		COALESCE(CAST(IsSettled as int), 0) IsSettled,
		COALESCE(CAST(PreviousIsSettled as int ), 0) PreviousIsSettled
		FROM
		(
			SELECT
			pl.PositionID
			,pl.CID
			,Occurred
			,CAST(pl.IsSettled AS INT)
			,CAST(pl.PreviousIsSettled AS INT)
			, ROW_NUMBER() over (partition by pl.PositionID order by  pl.Occurred ) rn
			FROM dwh_daily_process.daily_snapshot.etoro_History_PositionChangeLog pl 
			WHERE Occurred > DATEADD(DAY, DATEDIFF(-1, V_Yesterday), 0)
			---AND isnull(CAST(pl.IsSettled AS INT),-1) <> isnull(CAST(pl.PreviousIsSettled AS INT),-1)
			AND COALESCE(CAST(pl.IsSettled as int), 0) <> COALESCE(CAST(pl.PreviousIsSettled as int), 0)
		) a
		WHERE rn =1;
	
----------------------------------------------------------------->
TRUNCATE TABLE dwh_daily_process.migration_tables.Ext_Dim_Position_First_Open

;
	INSERT INTO dwh_daily_process.migration_tables.Ext_Dim_Position_First_Open
		SELECT
		PositionID,
		Occurred,
		CID,	
		COALESCE(CAST(IsSettled as int), 0) IsSettled
		
		FROM
		(
			SELECT
			pl.PositionID
			,pl.CID
			,Occurred
			,CAST(pl.IsSettled AS INT)
			, ROW_NUMBER() over (partition by pl.PositionID order by  pl.Occurred ) rn
			FROM dwh_daily_process.daily_snapshot.etoro_History_PositionChangeLog pl 
			WHERE Occurred >=V_Yesterday
			AND ChangeTypeID=0
			
		) a
		WHERE rn =1;






---------------------------------------------------------------------

-- Update Ext_Dim_Position_Real CAST(IsSettled AS INT) -------------------------------------------->
	MERGE INTO c A_TGT USING (
SELECT * 
FROM dwh_daily_process.migration_tables.Ext_Dim_Position_PositionChangeLog a
INNER JOIN dwh_daily_process.migration_tables.Ext_Dim_Position_Real c ON a.PositionID = c.PositionID ----------------------------------------------------------------->
 -- Update Ext_Dim_Position_History_Real  CAST(IsSettled AS INT) --------------->


QUALIFY ROW_NUMBER() OVER (PARTITION BY a.PositionID ORDER BY 1) = 1
)
ON a.PositionID = A_TGT.PositionID
WHEN MATCHED THEN UPDATE SET
IsSettled = CAST(PreviousIsSettled AS INT);
	MERGE INTO c A_TGT USING (
SELECT * 
FROM dwh_daily_process.migration_tables.Ext_Dim_Position_PositionChangeLog a
INNER JOIN dwh_daily_process.migration_tables.Ext_Dim_Position_History_Real c ON a.PositionID = c.PositionID ----------------------------------------------------------------->
 -- Ext_Dim_Position_PositionChangeLogAmount ----------------------------------------->


QUALIFY ROW_NUMBER() OVER (PARTITION BY a.PositionID ORDER BY 1) = 1
)
ON a.PositionID = A_TGT.PositionID
WHEN MATCHED THEN UPDATE SET
IsSettled = CAST(PreviousIsSettled AS INT);
TRUNCATE TABLE dwh_daily_process.migration_tables.Ext_Dim_Position_PositionChangeLogAmount
	
;
	INSERT INTO dwh_daily_process.migration_tables.Ext_Dim_Position_PositionChangeLogAmount
	SELECT         
	PositionID
	,CID
	,Occurred
	,PreviousAmount
	,PreviousStopRate
	FROM
	(
		SELECT
		PositionID
		,CID
		,Occurred
		,PreviousAmount 
		,PreviousStopRate, AmountChanged
		,ROW_NUMBER() over (partition by PositionID ORDER BY  Occurred ) rn
		FROM dwh_daily_process.daily_snapshot.etoro_History_PositionChangeLog 
		WHERE
		Occurred>= DATEADD(DAY, 1, V_Yesterday)
	) a
	WHERE rn=1
	

	;
TRUNCATE TABLE dwh_daily_process.migration_tables.Ext_Dim_Position_PositionChangeLogAmount_ChangeType12
	
;
	INSERT INTO dwh_daily_process.migration_tables.Ext_Dim_Position_PositionChangeLogAmount_ChangeType12
	SELECT
	PositionID
	,CID
	,SUM(AmountChanged) AS AmountChanged
	FROM dwh_daily_process.daily_snapshot.etoro_History_PositionChangeLog
	WHERE Occurred>= V_CurrentDate AND ChangeTypeID IN (12) 
	GROUP BY
	PositionID
	,CID;
	
----------------------------------------------------------------->

-- Update Ext_Dim_Position_History_Real - Amount ---------------->
	MERGE INTO dwh_daily_process.migration_tables.Ext_Dim_Position_History_Real a_TGT
USING (
SELECT * 
FROM dwh_daily_process.migration_tables.Ext_Dim_Position_History_Real a
INNER JOIN dwh_daily_process.migration_tables.Ext_Dim_Position_PositionChangeLogAmount b on a.PositionID = b.PositionID

QUALIFY ROW_NUMBER() OVER (PARTITION BY a.PositionID ORDER BY 1) = 1
)
ON a.PositionID = a_TGT.PositionID
WHEN MATCHED THEN UPDATE SET
Amount = b.PreviousAmount ,
StopRate = b.PreviousStopRate;
	MERGE INTO dwh_daily_process.migration_tables.Ext_Dim_Position_History_Real a_TGT
USING (
SELECT * 
FROM dwh_daily_process.migration_tables.Ext_Dim_Position_History_Real a
INNER JOIN dwh_daily_process.migration_tables.Ext_Dim_Position_PositionChangeLogAmount_ChangeType12 b ON a.PositionID = b.PositionID ----------------------------------------------------------------->
 -- Ext_Dim_Position_FundCIDs ------------------------------------>


QUALIFY ROW_NUMBER() OVER (PARTITION BY a.PositionID ORDER BY 1) = 1
)
ON a.PositionID = a_TGT.PositionID
WHEN MATCHED THEN UPDATE SET
Amount = a.Amount + b.AmountChanged;
TRUNCATE TABLE dwh_daily_process.migration_tables.Ext_Dim_Position_FundCIDs
	
;
	INSERT INTO dwh_daily_process.migration_tables.Ext_Dim_Position_FundCIDs
	
	SELECT b.CID
	FROM dwh_daily_process.daily_snapshot.etoro_BackOffice_Customer b  
	WHERE b.AccountTypeID=9;

----------------------------------------------------------------->

-- Update Ext_Dim_Position_Real - IsCopyFundPosition ------------------->
DROP VIEW IF EXISTS TEMP_TABLE_copyFundPos;

	CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_copyFundPos AS
SELECT
	    dp.PositionID
	   ,dp.CID
	   ,dp.TreeID 
	
	FROM dwh_daily_process.migration_tables.Ext_Dim_Position_Real dp
	JOIN dwh_daily_process.migration_tables.Dim_Position dp1
	 ON dp.TreeID = dp1.PositionID
	JOIN dwh_daily_process.migration_tables.Ext_Dim_Position_FundCIDs c
	 ON dp1.CID = c.CID;
	
	--CREATE CLUSTERED INDEX    #copyFundPos ON #copyFundPos (PositionID)
	MERGE INTO dwh_daily_process.migration_tables.Ext_Dim_Position_Real a_TGT
USING (
SELECT * 
FROM dwh_daily_process.migration_tables.Ext_Dim_Position_Real a
INNER JOIN TEMP_TABLE_copyFundPos b ON a.PositionID = b.PositionID ----------------------------------------------------------------->
 -- Update Ext_Dim_Position_History_Real - IsCopyFundPosition ------------>


QUALIFY ROW_NUMBER() OVER (PARTITION BY a.PositionID ORDER BY 1) = 1
)
ON a.PositionID = a_TGT.PositionID
WHEN MATCHED THEN UPDATE SET
IsCopyFundPosition = 1;
DROP VIEW IF EXISTS TEMP_TABLE_copyFundPos;

	CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_copyFundPos AS
SELECT
	    dp.PositionID
	   ,dp.CID
	   ,dp.TreeID 
	
	FROM dwh_daily_process.migration_tables.Ext_Dim_Position_History_Real dp
	JOIN dwh_daily_process.migration_tables.Dim_Position dp1
	 ON dp.TreeID = dp1.PositionID
	JOIN dwh_daily_process.migration_tables.Ext_Dim_Position_FundCIDs c
	 ON dp1.CID = c.CID;
	
	--CREATE NONCLUSTERED INDEX    #copyFundPos ON #copyFundPos (PositionID)
	MERGE INTO dwh_daily_process.migration_tables.Ext_Dim_Position_History_Real a_TGT
USING (
SELECT * 
FROM dwh_daily_process.migration_tables.Ext_Dim_Position_History_Real a
INNER JOIN TEMP_TABLE_copyFundPos b ON a.PositionID = b.PositionID ----------------------------------------------------------------->
 -- Ext_Dim_Position_AirDrop  ----------------------------->


QUALIFY ROW_NUMBER() OVER (PARTITION BY a.PositionID ORDER BY 1) = 1
)
ON a.PositionID = a_TGT.PositionID
WHEN MATCHED THEN UPDATE SET
IsCopyFundPosition = 1;
TRUNCATE TABLE dwh_daily_process.migration_tables.Ext_Dim_Position_AirDrop

;
	INSERT INTO dwh_daily_process.migration_tables.Ext_Dim_Position_AirDrop
	
	SELECT PositionID FROM dwh_daily_process.daily_snapshot.etoro_Trade_PositionAirdropLog
	WHERE PositionID IS NOT NULL 
	AND ExecutionOccurred >= V_Yesterday AND ExecutionOccurred < V_CurrentDate;
	
----------------------------------------------------------------->

-- Execute SQL Task Update from Ext_Dim_Position_AirDrop  Real ----------->
	MERGE INTO dwh_daily_process.migration_tables.Ext_Dim_Position_Real a_TGT
USING (
SELECT * 
from dwh_daily_process.migration_tables.Ext_Dim_Position_Real a
INNER JOIN dwh_daily_process.migration_tables.Ext_Dim_Position_AirDrop b ON a.PositionID = b.PositionID ----------------------------------------------------------------->
 -- Execute SQL Task Update from Ext_Dim_Position_AirDrop ---------------->


QUALIFY ROW_NUMBER() OVER (PARTITION BY a.PositionID ORDER BY 1) = 1
)
ON a.PositionID = a_TGT.PositionID
WHEN MATCHED THEN UPDATE SET
IsAirDrop = 1;
	MERGE INTO dwh_daily_process.migration_tables.Ext_Dim_Position_History_Real a_TGT
USING (
SELECT * 
FROM dwh_daily_process.migration_tables.Ext_Dim_Position_History_Real a
INNER JOIN dwh_daily_process.migration_tables.Ext_Dim_Position_AirDrop b ON a.PositionID = b.PositionID ----------------------------------------------------------------->
 -- Ext_Dim_Position_CurrencyPrice_Active ------------------------>


QUALIFY ROW_NUMBER() OVER (PARTITION BY a.PositionID ORDER BY 1) = 1
)
ON a.PositionID = a_TGT.PositionID
WHEN MATCHED THEN UPDATE SET
IsAirDrop = 1;
TRUNCATE TABLE dwh_daily_process.migration_tables.Ext_Dim_Position_CurrencyPrice_Active

;
	INSERT INTO dwh_daily_process.migration_tables.Ext_Dim_Position_CurrencyPrice_Active
	
	SELECT a.PriceRateID,
	 a.Ask, a.Bid, a.AskSpreaded, a.BidSpreaded, a.USDConversionRate,USDConversionRateBidSpreaded,USDConversionRateAskSpreaded,MarketPriceRateID
	FROM dwh_daily_process.daily_snapshot.PriceLog_History_CurrencyPrice_Active a
	WHERE Occurred>= DATEADD(HOUR, -1, V_Yesterday) AND Occurred <= V_CurrentDate;
	
----------------------------------------------------------------->
-- Update Ext_Dim_Position_Real - CurrencyPrice_Active  --------------------------->
	MERGE INTO dwh_daily_process.migration_tables.Ext_Dim_Position_Real p_TGT
USING (
SELECT * 
FROM dwh_daily_process.migration_tables.Ext_Dim_Position_Real p
INNER JOIN dwh_daily_process.migration_tables.Ext_Dim_Position_CurrencyPrice_Active a ON a.PriceRateID = p.InitForexPriceRateID ----------------------------------------------------------------->
 -- Update Ext_Dim_Position_History - CurrencyPrice_Active ------------>

)
ON 
COALESCE(p.InitForexPriceRateID::string,'__NULL__') = COALESCE(p_TGT.InitForexPriceRateID::string,'__NULL__')
WHEN MATCHED THEN UPDATE SET
`InitForex_Ask` = a.Ask ,
`InitForex_Bid` = a.Bid ,
`InitForex_AskSpreaded` = a.AskSpreaded ,
`InitForex_BidSpreaded` = a.BidSpreaded ,
`InitForex_USDConversionRate` = a.USDConversionRate;
	MERGE INTO dwh_daily_process.migration_tables.Ext_Dim_Position_History_Real p_TGT
USING (
SELECT * 
FROM dwh_daily_process.migration_tables.Ext_Dim_Position_History_Real p
INNER JOIN dwh_daily_process.migration_tables.Ext_Dim_Position_CurrencyPrice_Active a ON a.PriceRateID = p.InitForexPriceRateID
)
ON OpenDateID = date_format(CAST ( V_Yesterday as date ), 'yyyyMMdd') AND 
COALESCE(p.InitForexPriceRateID::string,'__NULL__') = COALESCE(p_TGT.InitForexPriceRateID::string,'__NULL__')
WHEN MATCHED THEN UPDATE SET
`InitForex_Ask` = a.Ask ,
`InitForex_Bid` = a.Bid ,
`InitForex_AskSpreaded` = a.AskSpreaded ,
`InitForex_BidSpreaded` = a.BidSpreaded ,
`InitForex_USDConversionRate` = a.USDConversionRate;
	MERGE INTO dwh_daily_process.migration_tables.Ext_Dim_Position_History_Real p_TGT
USING (
SELECT * 
FROM dwh_daily_process.migration_tables.Ext_Dim_Position_History_Real p
INNER JOIN dwh_daily_process.migration_tables.Ext_Dim_Position_CurrencyPrice_Active a ON a.PriceRateID = p.EndForexPriceRateID ----------------------------------------------------------------->
 -- Ext_Dim_Position_HBCExecutionLog ------------------------------>

)
ON 
COALESCE(p.EndForexPriceRateID::string,'__NULL__') = COALESCE(p_TGT.EndForexPriceRateID::string,'__NULL__')
WHEN MATCHED THEN UPDATE SET
`EndForex_Ask` = a.Ask ,
`EndForex_Bid` = a.Bid ,
`EndForex_AskSpreaded` = a.AskSpreaded ,
`EndForex_BidSpreaded` = a.BidSpreaded ,
`EndForex_USDConversionRate` = a.USDConversionRate;
TRUNCATE TABLE dwh_daily_process.migration_tables.Ext_Dim_Position_HBCExecutionLog

;
	INSERT INTO dwh_daily_process.migration_tables.Ext_Dim_Position_HBCExecutionLog
	
	SELECT ExecutionID, StartTime
	FROM dwh_daily_process.daily_snapshot.etoro_Hedge_HBCExecutionLog
	WHERE StartTime >= V_Yesterday AND  StartTime < V_CurrentDate;
	
----------------------------------------------------------------->
-- Update Ext_Dim_Position_Real - HedgeType  ---------------------->
call dwh_daily_process.migration_tables.SP_Dim_Position_HedgeType_History(V_Yesterday);
call dwh_daily_process.migration_tables.SP_Dim_Position_HedgeType_Real(V_Yesterday);
	MERGE INTO dwh_daily_process.migration_tables.Dim_Position a_TGT
USING (
SELECT * 
FROM dwh_daily_process.migration_tables.Dim_Position a
INNER JOIN dwh_daily_process.migration_tables.Ext_Dim_Position_History_Real b ON a.PositionID = b.PositionID --AND (a.CloseDateID = 19000101 or  a.CloseDateID = 0 ) --AND b.CloseDateID <> 0
 AND ( a.CloseOccurred = '19000101' or a.CloseDateID = 0 ) ---------------------------------------------------------------------------->
 -- Execute SQL Task Insert from Ext_Dim_Position_History ----------->


QUALIFY ROW_NUMBER() OVER (PARTITION BY a.PositionID ORDER BY 1) = 1
)
ON a.PositionID = a_TGT.PositionID
WHEN MATCHED THEN UPDATE SET
`AmountInUnitsDecimal` = b.`AmountInUnitsDecimal` ,
`InitForexRate` = b.`InitForexRate` ,
CloseOccurred = CASE WHEN b.CloseOccurred >= CAST ( current_timestamp() as date ) THEN '19000101' else b.CloseOccurred end ,
CloseDateID = CASE WHEN b.CloseOccurred >= CAST ( current_timestamp() as date ) THEN 0 ELSE CAST(date_format(DATEADD(DAY, DATEDIFF(0, b.CloseOccurred), 0), 'yyyyMMdd') AS int) END ,
NetProfit = b.NetProfit ,
CommissionOnClose = b.CommissionOnClose ,
Commission = b.Commission ,
MirrorID = b.MirrorID ,
ParentPositionID = b.ParentPositionID ,
OrigParentPositionID = b.OrigParentPositionID ,
Amount = b.Amount ,
CloseOnEndOfWeek = b.CloseOnEndOfWeek ,
EndOfWeekFee = b.EndOfWeekFee ,
EndForexRate = b.EndForexRate ,
LastOpConversionRate = b.LastOpConversionRate ,
LimitRate = b.LimitRate ,
StopRate = b.StopRate ,
ClosePositionReasonID = b.ClosePositionReasonID ,
TreeID = b.TreeID ,
HedgeID = b.HedgeID ,
HedgeServerID = b.HedgeServerID ,
UpdateDate = current_timestamp() ,
FullCommission = b.FullCommission ,
FullCommissionOnClose = b.FullCommissionOnClose ,
IsComputeForHedge = b.IsComputeForHedge ,
IsSettled = b.IsSettled ,
InitialAmountCents = b.InitialAmountCents ,
RedeemStatus = b.RedeemStatus ,
RedeemID = b.RedeemID ,
InitialUnits = b.InitialUnits ,
IsDiscounted = b.IsDiscounted ,
CommissionByUnits = b.CommissionByUnits ,
FullCommissionByUnits = b.FullCommissionByUnits ,
Volume = b.Volume ,
VolumeOnClose = b.VolumeOnClose --,InitForexPriceRateID = b.InitForexPriceRateID
 ,
EndForexPriceRateID = b.EndForexPriceRateID --,[InitForex_Ask] = b.InitForex_Ask
 --,[InitForex_Bid] = b.InitForex_Bid
 --,[InitForex_AskSpreaded] = b.InitForex_AskSpreaded
 --,[InitForex_BidSpreaded] = b.InitForex_BidSpreaded
 --,[InitForex_USDConversionRate] = b.InitForex_USDConversionRate
 ,
`EndForex_Ask` = b.EndForex_Ask ,
`EndForex_Bid` = b.EndForex_Bid ,
`EndForex_AskSpreaded` = b.EndForex_AskSpreaded ,
`EndForex_BidSpreaded` = b.EndForex_BidSpreaded ,
`EndForex_USDConversionRate` = b.EndForex_USDConversionRate ,
`InitExecutionID` = b.`InitExecutionID` ,
`EndExecutionID` = b.`EndExecutionID` -------,InitHedgeType = b.InitHedgeType
 ,
EndHedgeType = b.EndHedgeType ,
CloseMarketPriceRateID = b.CloseMarketPriceRateID ,
ExitOrderID = b.ExitOrderID ,
LastOpPriceRate = b.LastOpPriceRate ,
RequestOpenOccurred = b.RequestOpenOccurred ,
RequestCloseOccurred = b.RequestCloseOccurred ,
OrderType = b.OrderType ,
`InitConversionRate` = b.`InitConversionRate` -- 20240103 KatyF
 ,
`PnLVersion` = b.`PnLVersion` -- 20240103 KatyF
 ,
PnLInDollars = b.EndOfDayPnLInDollars -- 20240115 Inbal BML
 ,
OpenMarketSpread = b.OpenMarketSpread --20240115 Inbal BML
 ,
CloseMarketSpread = b.CloseMarketSpread --20240115 Inbal BML
 ,
CloseMarkupOnOpen = b.CloseMarkupOnOpen --20240115 Inbal BML
 ,
OpenMarkup = b.OpenMarkup --20240115 Inbal BML
 ,
CloseMarkup = b.CloseMarkup --20240115 Inbal BML
;
	INSERT into dwh_daily_process.migration_tables.Dim_Position 
	     (  `PositionID`
	      , `CID`
	      , `CurrencyID`
	      , `ProviderID`
	      , `InstrumentID`
	      , `HedgeID`
	      , `HedgeServerID`
	      , `Leverage`
	      , `Amount`
	      , `AmountInUnitsDecimal`
	      , `UnitMargin`
	      , `InitForexRate`
	      , `NetProfit`
	      , `SpreadedPipBid`
	      , `SpreadedPipAsk`
	      , `IsBuy`
	      , `CloseOnEndOfWeek`
	      , `EndOfWeekFee`
	      , `Commission`
	      , `CommissionOnClose`
	      , `OpenOccurred`
	      , `CloseOccurred`
	      , `ParentPositionID`
	      , `OrigParentPositionID`
	      , `MirrorID`
	      , `IsOpenOpen`
	      , `LotCountDecimal`
	      , `SpreadedCommission`
	      , `EndForexRate`
	      , `LastOpConversionRate`
	      , `LimitRate`
	      , `StopRate`
	      , `ClosePositionReasonID`
	      , `TreeID`
	      , `OpenDateID`
	      , `CloseDateID`
	      , `RegulationIDOnOpen`
	      , `UpdateDate`
	      , `FullCommission`
	      , `FullCommissionOnClose`
	      , IsComputeForHedge
	      , IsSettled
	      , InitialAmountCents
	      , RedeemStatus
	      , RedeemID
	      , ReopenForPositionID
	      , IsReOpen
	      , CommissionOnCloseOrig
	      , FullCommissionOnCloseOrig
	      , OriginalPositionID
	      , IsPartialCloseChild
	      , InitialUnits
	      , IsDiscounted
	      , CommissionByUnits
	      , FullCommissionByUnits
	      , Volume
	      , VolumeOnClose
	      , LastOpPriceRateID
	      , IsAirDrop
	      , InitForexPriceRateID
	      , EndForexPriceRateID
	      , `InitForex_Ask` 
	      , `InitForex_Bid` 
	      , `InitForex_AskSpreaded` 
	      , `InitForex_BidSpreaded` 
	      , `InitForex_USDConversionRate` 
	      , `EndForex_Ask` 
	      , `EndForex_Bid`
	      , `EndForex_AskSpreaded` 
	      , `EndForex_BidSpreaded`
	      , `EndForex_USDConversionRate`
	      , `InitExecutionID`
	      , `EndExecutionID`
	      , `InitConversionRate`
	      , `InitConversionRateID`
	      , CloseMarketPriceRateID
	      , InitHedgeType 
	      , EndHedgeType 
	      , OrderID
	      , ExitOrderID
	      , IsSettledOnOpen
	      , StopRateOnOpen
	      , LimitRateOnOpen
	      , `LastOpPriceRate`
	      , `SettlementTypeID`
	      , OpenMarketPriceRateID
	      , CloseMarket_AskSpreaded
	      , CloseMarket_BidSpreaded
	      , CloseMarket_Ask 
	      , CloseMarket_Bid
	      , CloseMarketCoversionRateBidSpreaded
	      , CloseMarketCoversionRateAskSpreaded
	      , RequestOpenOccurred
	      , RequestCloseOccurred
	      , OrderType
	      , `PnLVersion` -- 20240103 KatyF
	      , PnLInDollars -- 20240115 Inbal BML
		  , OpenMarketSpread --20240115 Inbal BML
		  , CloseMarketSpread --20240115 Inbal BML
		  , CloseMarkupOnOpen --20240115 Inbal BML
		  , OpenMarkup --20240115 Inbal BML
		  , CloseMarkup --20240115 Inbal BML

	)
	
	SELECT  b.`PositionID`
	      , b.`CID`
	      , b.`CurrencyID`
	      , b.`ProviderID`
	      , b.`InstrumentID`
	      , b.`HedgeID`
	      , b.`HedgeServerID`
	      , b.`Leverage`
	      , b.`Amount`
	      , b.`AmountInUnitsDecimal`
	      , b.`UnitMargin`
	      , b.`InitForexRate`
	      , b.`NetProfit`
	      , b.`SpreadedPipBid`
	      , b.`SpreadedPipAsk`
	      , b.`IsBuy`
	      , b.`CloseOnEndOfWeek`
	      , b.`EndOfWeekFee`
	      , b.`Commission`
	      , b.`CommissionOnClose`
	      , b.`OpenOccurred`
	      , CASE WHEN b.CloseOccurred  >=CAST(current_timestamp() as date)  THEN '19000101' ELSE b.CloseOccurred  END as CloseOccurred
	    -- , b.[CloseOccurred]
	      , b.`ParentPositionID`
	      , b.`OrigParentPositionID`
	      , b.`MirrorID`
	      , b.`IsOpenOpen`
	      , b.`LotCountDecimal`
	      , b.`SpreadedCommission`
	      , b.`EndForexRate`
	      , b.`LastOpConversionRate`
	      , b.`LimitRate`
	      , b.`StopRate`
	      , b.`ClosePositionReasonID`
	      , b.`TreeID`
	      , b.`OpenDateID`
	      , CASE WHEN b.CloseOccurred >=CAST(current_timestamp() as date)  THEN 0 ELSE CAST(date_format(DATEADD(DAY, DATEDIFF(0, b.CloseOccurred), 0), 'yyyyMMdd') AS int) END AS CloseDateID
	    --, b.[CloseDateID]
	      , COALESCE(b.`RegulationID`, 0)
	      , current_timestamp()
	      , b.`FullCommission`
	      , b.`FullCommissionOnClose`
	      , b.IsComputeForHedge
	      , CAST(b.IsSettled AS INT)
	      , b.InitialAmountCents
	      , b.RedeemStatus
	      , b.RedeemID
	      , b.ReopenForPositionID
	      , b.IsReOpen
	      , b.CommissionOnCloseOrig
	      , b.FullCommissionOnCloseOrig
	      , b.OriginalPositionID
	      , CASE WHEN b.PositionID <>   b.OriginalPositionID   AND  b.OriginalPositionID  is not null THEN 1 else  0 end IsPartialCloseChild
	      , b.InitialUnits
	      , CAST(b.IsDiscounted AS INT)
	      , b.CommissionByUnits
	      , b.FullCommissionByUnits
	      , b.Volume
	      , b.VolumeOnClose
	      , b.LastOpPriceRateID
	      , b.IsAirDrop
	      , b.InitForexPriceRateID
	      , b.EndForexPriceRateID
	      , b.`InitForex_Ask` 
	      , b.`InitForex_Bid` 
	      , b.`InitForex_AskSpreaded` 
	      , b.`InitForex_BidSpreaded` 
	      , b.`InitForex_USDConversionRate` 
	      , b.`EndForex_Ask` 
	      , b.`EndForex_Bid`
	      , b.`EndForex_AskSpreaded` 
	      , b.`EndForex_BidSpreaded`
	      , b.`EndForex_USDConversionRate` 
	      , b.`InitExecutionID`
	      , CASE WHEN b.CloseOccurred  >=CAST(current_timestamp() as date)  
	        THEN 0 
	        ELSE b.`EndExecutionID` 
	        END EndExecutionID
	      --b.[EndExecutionID]
	      , b.`InitConversionRate`
	      , b.`InitConversionRateID`
	      , b.CloseMarketPriceRateID
	      , b.InitHedgeType 
	      , CASE WHEN b.CloseOccurred  >=CAST(current_timestamp() as date)  
	        THEN NULL
	        ELSE b.EndHedgeType 
	        END EndHedgeType
	      --,b.EndHedgeType 
	      , b.OrderID
	      , b.ExitOrderID
	      , COALESCE(CAST(c.IsSettled AS INT), 0) AS IsSettledOnOpen
	      , COALESCE(b.StopRate, 0) AS StopRateOnOpen
	      , COALESCE(b.LimitRate, 0) AS LimitRateOnOpen
	      , b.`LastOpPriceRate`
	      , b.SettlementTypeID
	      , b.OpenMarketPriceRateID
	      , b.CloseMarket_AskSpreaded
	      , b.CloseMarket_BidSpreaded
	      , b.CloseMarket_Ask 
	      , b.CloseMarket_Bid
	      , b.CloseMarketCoversionRateBidSpreaded
	      , b.CloseMarketCoversionRateAskSpreaded
	      , b.RequestOpenOccurred
	      , b.RequestCloseOccurred
	      , b.OrderType
	      , b.`PnLVersion`  -- 20240103 KatyF
	      , b.EndOfDayPnLInDollars as PnLInDollars -- 20240115 Inbal BML
		  , b.OpenMarketSpread --20240115 Inbal BML
		  , b.CloseMarketSpread --20240115 Inbal BML
		  , b.CloseMarkupOnOpen --20240115 Inbal BML
		  , b.OpenMarkup --20240115 Inbal BML
		  , b.CloseMarkup --20240115 Inbal BML
	FROM dwh_daily_process.migration_tables.Ext_Dim_Position_History_Real AS b
	left join dwh_daily_process.migration_tables.Dim_Position a
	ON b.PositionID = a.PositionID
	left join dwh_daily_process.migration_tables.Ext_Dim_Position_First_Open c
	on b.PositionID = c.PositionID
	WHERE
	(
		(b.CloseDateID >= CAST(date_format(V_Yesterday, 'yyyyMMdd') AS int) AND b.OpenDateID =  CAST(date_format(V_Yesterday, 'yyyyMMdd') AS int))
		
		OR( b.OriginalPositionID <> b.PositionID AND b.CloseDateID >= CAST(date_format(V_Yesterday, 'yyyyMMdd') AS int)  AND 
		b.CloseDateID < CAST(date_format(DATEADD(day, 1, V_Yesterday), 'yyyyMMdd') AS int)   ) -- Partial close position
	)
	AND a.PositionID IS NULL;

	----------------------------------------------------------------->----------------------------------------------------------------->
-- Remove Duplicate Positions -------------------->----------------------------------------------------------------->
  
-- [stub] MERGE-with-empty-ON elided (Synapse index rebuild has no UC equivalent)

	MERGE INTO dwh_daily_process.migration_tables.Ext_Dim_Position_Real a_TGT
USING (
SELECT * 
FROM dwh_daily_process.migration_tables.Ext_Dim_Position_Real a
INNER JOIN dwh_daily_process.migration_tables.Ext_Dim_Position_PositionChangeLogAmount b ON a.PositionID = b.PositionID

QUALIFY ROW_NUMBER() OVER (PARTITION BY a.PositionID ORDER BY 1) = 1
)
ON a.PositionID = a_TGT.PositionID
WHEN MATCHED THEN UPDATE SET
Amount = b.PreviousAmount ,
StopRate = b.PreviousStopRate;
	MERGE INTO dwh_daily_process.migration_tables.Ext_Dim_Position_Real a_TGT
USING (
SELECT * 
FROM dwh_daily_process.migration_tables.Ext_Dim_Position_Real a
INNER JOIN dwh_daily_process.migration_tables.Ext_Dim_Position_PositionChangeLogAmount_ChangeType12 b ON a.PositionID = b.PositionID -----------------------------------------------------------------> 
 -- SQL Task Update from Ext_Dim_Position_Real ---------------------->
 --UPDATE STATISTICS [DWH_dbo].[Dim_Position]
 --Added by Boris P 2024-04-09


QUALIFY ROW_NUMBER() OVER (PARTITION BY a.PositionID ORDER BY 1) = 1
)
ON a.PositionID = a_TGT.PositionID
WHEN MATCHED THEN UPDATE SET
Amount = a.Amount + b.AmountChanged;

SET V_upsts = (
SELECT
'UPDATE STATISTICS [DWH_dbo].[Dim_Position] ['+name+']' FROM sys.indexes 
WHERE object_id=NULL and type_desc='CLUSTERED'

 LIMIT 1);
IF V_upsts is not null 
THEN
EXECUTE IMMEDIATE V_upsts;
	--PRINT @upsts
END IF;
	MERGE INTO dwh_daily_process.migration_tables.Dim_Position t_TGT
USING (
SELECT * 
FROM dwh_daily_process.migration_tables.Dim_Position t
INNER JOIN dwh_daily_process.migration_tables.Ext_Dim_Position_Real s ON t.PositionID = s.PositionID ---- AND t.[OpenDateID] = s.[OpenDateID] ---<<<<<-
 AND EXISTS ( SELECT COALESCE(t.ParentPositionID, 0) , COALESCE(t.AmountInUnitsDecimal, 0) , COALESCE(t.InitForexRate, 0) , COALESCE(t.Amount, 0) , COALESCE(CAST(t.CloseOnEndOfWeek AS BOOLEAN), FALSE) , COALESCE(t.EndOfWeekFee, 0) , COALESCE(t.LastOpConversionRate, 0) , COALESCE(t.LimitRate, 0) , COALESCE(t.StopRate, 0) , COALESCE(t.TreeID, 0) , COALESCE(t.HedgeID, 0) , COALESCE(t.HedgeServerID, 0) , COALESCE(t.FullCommission, 0) , COALESCE(t.IsComputeForHedge, 0) , COALESCE(CAST(t.IsSettled AS INT), 0) , COALESCE(t.InitialAmountCents, 0) , COALESCE(t.RedeemStatus, 0) , COALESCE(t.InitialUnits, 0) , COALESCE(CAST(t.IsDiscounted AS INT), 0) , COALESCE(t.CommissionByUnits, 0) , COALESCE(t.FullCommissionByUnits, 0) , COALESCE(t.Volume, 0) , COALESCE(t.VolumeOnClose, 0) , COALESCE(t.MirrorID, 0) , COALESCE(t.InitConversionRate, 0.00) , COALESCE(t.PnLVersion, - 1) -- 20240103 KatyF
 , COALESCE(t.PnLInDollars, 0) , COALESCE(t.OpenMarketSpread, 0) , COALESCE(t.CloseMarkupOnOpen, 0) , COALESCE(t.OpenMarkup, 0) --20240115 Inbal BML
 EXCEPT SELECT COALESCE(s.ParentPositionID, 0) , COALESCE(s.AmountInUnitsDecimal, 0) , COALESCE(s.InitForexRate, 0) , COALESCE(s.Amount, 0) , COALESCE(CAST(s.CloseOnEndOfWeek AS BOOLEAN), FALSE) , COALESCE(s.EndOfWeekFee, 0) , COALESCE(s.LastOpConversionRate, 0) , COALESCE(s.LimitRate, 0) , COALESCE(s.StopRate, 0) , COALESCE(s.TreeID, 0) , COALESCE(s.HedgeID, 0) , COALESCE(s.HedgeServerID, 0) , COALESCE(s.FullCommission, 0) , COALESCE(s.IsComputeForHedge, 0) , COALESCE(CAST(s.IsSettled AS INT), 0) , COALESCE(s.InitialAmountCents, 0) , COALESCE(s.RedeemStatus, 0) , COALESCE(s.InitialUnits, 0) , COALESCE(CAST(s.IsDiscounted AS INT), 0) , COALESCE(s.CommissionByUnits, 0) , COALESCE(s.FullCommissionByUnits, 0) , COALESCE(s.Volume, 0) , COALESCE(s.VolumeOnClose, 0) , COALESCE(s.MirrorID, 0) , COALESCE(s.InitConversionRate, 0.00) , COALESCE(s.PnLVersion, 0) -- 20240103 KatyF
 , COALESCE(s.PnLInDollars, 0) , COALESCE(s.OpenMarketSpread, 0) , COALESCE(s.CloseMarkupOnOpen, 0) , COALESCE(s.OpenMarkup, 0) --20240115 Inbal BML
 ) -----------------------------------------------------------------> 
 -- SQL Task Insert from Ext_Dim_Position_Real --------------------->


QUALIFY ROW_NUMBER() OVER (PARTITION BY t.PositionID ORDER BY 1) = 1
)
ON t.PositionID = t_TGT.PositionID
WHEN MATCHED THEN UPDATE SET
ParentPositionID = s.ParentPositionID ,
AmountInUnitsDecimal = s.AmountInUnitsDecimal ,
InitForexRate = s.InitForexRate ,
Amount = s.Amount ,
CloseOnEndOfWeek = s.CloseOnEndOfWeek ,
EndOfWeekFee = s.EndOfWeekFee ,
LastOpConversionRate = s.LastOpConversionRate ,
LimitRate = s.LimitRate ,
StopRate = s.StopRate ,
TreeID = s.TreeID ,
HedgeID = s.HedgeID ,
HedgeServerID = s.HedgeServerID ,
UpdateDate = current_timestamp() ,
FullCommission = s.FullCommission ,
IsComputeForHedge = s.IsComputeForHedge ,
IsSettled = s.IsSettled ,
InitialAmountCents = s.InitialAmountCents ,
RedeemStatus = s.RedeemStatus ,
InitialUnits = s.InitialUnits ,
IsDiscounted = s.IsDiscounted ,
CommissionByUnits = s.CommissionByUnits ,
FullCommissionByUnits = s.FullCommissionByUnits ,
Volume = s.Volume ,
VolumeOnClose = s.VolumeOnClose ,
MirrorID = s.MirrorID ,
RequestOpenOccurred = s.RequestOccurred ,
OrderType = s.OrderType ,
`InitConversionRate` = s.`InitConversionRate` -- 20240103 KatyF
 ,
`PnLVersion` = s.`PnLVersion` -- 20240103 KatyF
 ,
PnLInDollars = s.PnLInDollars --20240115 Inbal BML
 ,
OpenMarketSpread = s.OpenMarketSpread --20240115 Inbal BML
 ,
CloseMarkupOnOpen = s.CloseMarkupOnOpen --20240115 Inbal BML
 ,
OpenMarkup = s.OpenMarkup --20240115 Inbal BML
;
	INSERT INTO dwh_daily_process.migration_tables.Dim_Position
	     (`PositionID`
	    , `CID`
	    , `CurrencyID`
	    , `ProviderID`
	    , `InstrumentID`
	    , `HedgeID`
	    , `HedgeServerID`
	    , `Leverage`
	    , `Amount`
	    , `AmountInUnitsDecimal`
	    , `UnitMargin`
	    , `InitForexRate`
	    , `NetProfit`
	    , `SpreadedPipBid`
	    , `SpreadedPipAsk`
	    , `IsBuy`
	    , `CloseOnEndOfWeek`
	    , `EndOfWeekFee`
	    , `Commission`
	    , `CommissionOnClose`
	    , `OpenOccurred`
	    , `CloseOccurred`
	    , `ParentPositionID`
	    , `OrigParentPositionID`
	    , `MirrorID`
	    , `IsOpenOpen`
	    , `LotCountDecimal`
	    , `SpreadedCommission`
	    , `EndForexRate`
	    , `LastOpConversionRate`
	    , `LimitRate`
	    , `StopRate`
	    , `ClosePositionReasonID`
	    , `TreeID`
	    , `OpenDateID`
	    , `CloseDateID`
	    , `RegulationIDOnOpen`
	    , `UpdateDate`
	    , `FullCommission`
	    , `FullCommissionOnClose`
	    , IsComputeForHedge
	    , IsSettled
	    , InitialAmountCents
	    , RedeemStatus
	    , RedeemID
	    , ReopenForPositionID
	    , IsReOpen
	    , CommissionOnCloseOrig
	    , FullCommissionOnCloseOrig
	    , InitialUnits
	    , IsDiscounted
	    , CommissionByUnits
	    , FullCommissionByUnits
	    , Volume
	    , VolumeOnClose 
	    , LastOpPriceRateID 
	    , IsAirDrop
	    , InitForexPriceRateID
	    , `InitForex_Ask` 
	    , `InitForex_Bid` 
	    , `InitForex_AskSpreaded` 
	    , `InitForex_BidSpreaded` 
	    , `InitForex_USDConversionRate` 
	    , InitExecutionID
	    , `InitConversionRate`
	    , `InitConversionRateID`
	    , InitHedgeType 
	    , OrderID
	    , IsSettledOnOpen
	    , StopRateOnOpen
	    , LimitRateOnOpen
	    , SettlementTypeID
	    , OpenMarketPriceRateID
	    , OpenMarket_Ask 
	    , OpenMarket_Bid 
	    , OpenMarket_AskSpreaded 
	    , OpenMarket_BidSpreaded 
	    , OpenMarketCoversionRateBidSpreaded
	    , OpenMarketCoversionRateAskSpreaded
	    , RequestOpenOccurred
        , OrderType
	    , PnLVersion -- 20240103 KatyF
		, PnLInDollars  --20240115 Inbal BML
		, OpenMarketSpread --20240115 Inbal BML
		, CloseMarkupOnOpen --20240115 Inbal BML
		, OpenMarkup --20240115 Inbal BML

	 )
	SELECT 
	     b.`PositionID`
	   , b.`CID`
	   , b.`CurrencyID`
	   , b.`ProviderID`
	   , b.`InstrumentID`
	   , b.`HedgeID`
	   , b.`HedgeServerID`
	   , b.`Leverage`
	   , b.`Amount`
	   , b.`AmountInUnitsDecimal`
	   , b.`UnitMargin`
	   , b.`InitForexRate`
	   , b.`NetProfit`
	   , b.`SpreadedPipBid`
	   , b.`SpreadedPipAsk`
	   , b.`IsBuy`
	   , b.`CloseOnEndOfWeek`
	   , b.`EndOfWeekFee`
	   , b.`Commission`
	   , b.`CommissionOnClose`
	   , b.`OpenOccurred`
	   , b.`CloseOccurred`
	   , b.`ParentPositionID`
	   , b.`OrigParentPositionID`
	   , b.`MirrorID`
	   , b.`IsOpenOpen`
	   , b.`LotCountDecimal`
	   , b.`SpreadedCommission`
	   , b.`EndForexRate`
	   , b.`LastOpConversionRate`
	   , b.`LimitRate`
	   , b.`StopRate`
	   , b.`ClosePositionReasonID`
	   , b.`TreeID`
	   , b.`OpenDateID`
	   , b.`CloseDateID`
	   , COALESCE(b.`RegulationID`, 0) AS RegulationIDOnOpen
	   , current_timestamp()
	   , b.`FullCommission`
	   , b.`FullCommissionOnClose`
	   , b.IsComputeForHedge
	   , CAST(b.IsSettled AS INT)
	   , b.InitialAmountCents
	   , b.RedeemStatus
	   , b.RedeemID
	   , b.ReopenForPositionID
	   , b.IsReOpen
	   , b.CommissionOnCloseOrig
	   , b.FullCommissionOnCloseOrig
	   , b.InitialUnits
	   , CAST(b.IsDiscounted AS INT)
	   , b.CommissionByUnits
	   , b.FullCommissionByUnits
	   , b.Volume
	   , b.VolumeOnClose
	   , b.LastOpPriceRateID
	   , b.IsAirDrop
	   , b.InitForexPriceRateID
	   , b.`InitForex_Ask` 
	   , b.`InitForex_Bid` 
	   , b.`InitForex_AskSpreaded` 
	   , b.`InitForex_BidSpreaded` 
	   , b.`InitForex_USDConversionRate` 
	   , b.InitExecutionID
	   , b.`InitConversionRate`
	   , b.`InitConversionRateID`
	   , b.InitHedgeType 
	   , b.OrderID
	   , COALESCE(CAST(c.IsSettled AS INT), 0) AS IsSettledOnOpen
	   , COALESCE(b.StopRate, 0) AS StopRateOnOpen
	   , COALESCE(b.LimitRate, 0) AS LimitRateOnOpen
	   , b.SettlementTypeID
	   , b.OpenMarketPriceRateID
	   , b.OpenMarket_Ask 
	   , b.OpenMarket_Bid 
	   , b.OpenMarket_AskSpreaded 
	   , b.OpenMarket_BidSpreaded 
	   , b.OpenMarketCoversionRateBidSpreaded
	   , b.OpenMarketCoversionRateAskSpreaded
	   , RequestOccurred
       , b.OrderType
	   , b.PnLVersion -- 20240103 KatyF
	   , b.PnLInDollars  --20240115 Inbal BML
	   , b.OpenMarketSpread --20240115 Inbal BML
	   , b.CloseMarkupOnOpen --20240115 Inbal BML
	   , b.OpenMarkup --20240115 Inbal BML
	FROM  dwh_daily_process.migration_tables.Ext_Dim_Position_Real AS b 
	left join  dwh_daily_process.migration_tables.Dim_Position AS a
	ON a.PositionID = b.PositionID
	left join dwh_daily_process.migration_tables.Ext_Dim_Position_First_Open as c
	ON b.PositionID = c.PositionID
	WHERE a.PositionID IS NULL;
-----------------------------------------------------------------> 
-- Update InitForex Dim_Position PatitialClose ------------------>
	MERGE INTO dwh_daily_process.migration_tables.Dim_Position a_TGT
USING (
SELECT * 
FROM dwh_daily_process.migration_tables.Dim_Position a
INNER JOIN dwh_daily_process.migration_tables.Dim_Position b ON a.OriginalPositionID = b.PositionID

QUALIFY ROW_NUMBER() OVER (PARTITION BY a.OriginalPositionID ORDER BY 1) = 1
)
ON a.OriginalPositionID = a_TGT.OriginalPositionID
WHEN MATCHED THEN UPDATE SET
`InitForex_Ask` = b.`InitForex_Ask` ,
`InitForex_Bid` = b.`InitForex_Bid` ,
`InitForex_AskSpreaded` = b.`InitForex_AskSpreaded` ,
`InitForex_BidSpreaded` = b.`InitForex_BidSpreaded` ,
`InitForex_USDConversionRate` = b.`InitForex_USDConversionRate`;
	MERGE INTO dwh_daily_process.migration_tables.Dim_Position a_TGT
USING (
SELECT * 
FROM dwh_daily_process.migration_tables.Dim_Position a
INNER JOIN dwh_daily_process.migration_tables.Dim_Position b ON a.OriginalPositionID = b.PositionID

QUALIFY ROW_NUMBER() OVER (PARTITION BY a.OriginalPositionID ORDER BY 1) = 1
)
ON a.OriginalPositionID = a_TGT.OriginalPositionID
WHEN MATCHED THEN UPDATE SET
RegulationIDOnOpen = b.RegulationIDOnOpen;
call dwh_daily_process.migration_tables.SP_Dim_Position_ReOpen(V_Yesterday);
call dwh_daily_process.migration_tables.SP_Dim_Position_IsPartialCloseParent();
MERGE INTO dwh_daily_process.migration_tables.Dim_Position p_TGT
USING (
SELECT * 
FROM dwh_daily_process.migration_tables.Dim_Position p
INNER JOIN dwh_daily_process.daily_snapshot.PriceLog_History_CurrencyPrice_Active_5_days a ON a.PriceRateID = p.CloseMarketPriceRateID AND a.InstrumentID = p.InstrumentID AND CAST(a.Occurred AS date) BETWEEN DATEADD(DAY, - 5, CAST(CAST(p.CloseDateID AS STRING) AS date)) AND CAST(CAST(p.CloseDateID AS STRING) AS date)
)
ON p.CloseDateID = CAST ( date_format(V_Yesterday, 'yyyyMMdd') AS INT ) -- all positions where the PriceRateID is found will be updated 
 AND 
COALESCE(p.CloseMarketPriceRateID::string,'__NULL__') = COALESCE(p_TGT.CloseMarketPriceRateID::string,'__NULL__') AND 
COALESCE(p.InstrumentID::string,'__NULL__') = COALESCE(p_TGT.InstrumentID::string,'__NULL__') AND 
COALESCE(p.CloseDateID::string,'__NULL__') = COALESCE(p_TGT.CloseDateID::string,'__NULL__')
WHEN MATCHED THEN UPDATE SET
CloseMarket_AskSpreaded = a.AskSpreaded ,
CloseMarket_BidSpreaded = a.BidSpreaded ,
CloseMarket_Ask = a.Ask ,
CloseMarket_Bid = a.Bid ,
CloseMarketCoversionRateBidSpreaded = a.USDConversionRateBidSpreaded ,
CloseMarketCoversionRateAskSpreaded = a.USDConversionRateAskSpreaded;
    MERGE INTO dwh_daily_process.migration_tables.Dim_Position p_TGT
USING (
SELECT * 
FROM dwh_daily_process.migration_tables.Dim_Position p
INNER JOIN dwh_daily_process.daily_snapshot.PriceLog_History_CurrencyPrice_Active_5_days a ON MarketPriceRateID = p.CloseMarketPriceRateID AND a.InstrumentID = p.InstrumentID
)
ON CloseMarket_AskSpreaded IS NULL AND CAST(a.Occurred AS date) BETWEEN DATEADD(DAY, - 5, CAST(CAST(p.CloseDateID AS STRING) AS date)) AND CAST(CAST(p.CloseDateID AS STRING) AS date) and p.CloseDateID = CAST ( date_format(V_Yesterday, 'yyyyMMdd') AS INT ) -- this condition should join the only positions which are still null where MarketPriceRateID is found in the Ext table but not PriceRateID
 -- step 1: update on PriceRateID. example for this: Position 2394055999, PriceRateID = 64496832199, MarketPriceRateID = 650511496561, we want to 
 -- join on PriceRateID if exists, then go over the nulls and join the remaining on MarketPriceRateID:
 AND 
COALESCE(p.CloseMarketPriceRateID::string,'__NULL__') = COALESCE(p_TGT.CloseMarketPriceRateID::string,'__NULL__') AND 
COALESCE(p.InstrumentID::string,'__NULL__') = COALESCE(p_TGT.InstrumentID::string,'__NULL__') AND 
COALESCE(p.CloseDateID::string,'__NULL__') = COALESCE(p_TGT.CloseDateID::string,'__NULL__')
WHEN MATCHED THEN UPDATE SET
CloseMarket_AskSpreaded = a.AskSpreaded ,
CloseMarket_BidSpreaded = a.BidSpreaded ,
CloseMarket_Ask = a.Ask ,
CloseMarket_Bid = a.Bid ,
CloseMarketCoversionRateBidSpreaded = a.USDConversionRateBidSpreaded ,
CloseMarketCoversionRateAskSpreaded = a.USDConversionRateAskSpreaded;
    MERGE INTO dwh_daily_process.migration_tables.Dim_Position p_TGT
USING (
SELECT * 
FROM dwh_daily_process.migration_tables.Dim_Position p --[DWH_dbo].Ext_Dim_Position_Real p

INNER JOIN dwh_daily_process.daily_snapshot.PriceLog_History_CurrencyPrice_Active_5_days a ON a.PriceRateID = p.OpenMarketPriceRateID AND a.InstrumentID = p.InstrumentID AND CAST(a.Occurred AS date) BETWEEN DATEADD(DAY, - 5, CAST(CAST(p.OpenDateID AS STRING) AS date)) AND CAST(CAST(p.OpenDateID AS STRING) AS date)
)
ON p.OpenDateID = CAST ( date_format(V_Yesterday, 'yyyyMMdd') AS INT ) -- all positions where the PriceRateID is found will be updated 
 AND 
COALESCE(p.OpenMarketPriceRateID::string,'__NULL__') = COALESCE(p_TGT.OpenMarketPriceRateID::string,'__NULL__') AND 
COALESCE(p.InstrumentID::string,'__NULL__') = COALESCE(p_TGT.InstrumentID::string,'__NULL__') AND 
COALESCE(p.OpenDateID::string,'__NULL__') = COALESCE(p_TGT.OpenDateID::string,'__NULL__')
WHEN MATCHED THEN UPDATE SET
OpenMarket_Ask = a.Ask ,
OpenMarket_Bid = a.Bid ,
OpenMarket_AskSpreaded = a.AskSpreaded ,
OpenMarket_BidSpreaded = a.BidSpreaded ,
OpenMarketCoversionRateBidSpreaded = a.USDConversionRateBidSpreaded ,
OpenMarketCoversionRateAskSpreaded = a.USDConversionRateAskSpreaded;
    MERGE INTO dwh_daily_process.migration_tables.Dim_Position p_TGT
USING (
SELECT * 
FROM dwh_daily_process.migration_tables.Dim_Position p
INNER JOIN dwh_daily_process.daily_snapshot.PriceLog_History_CurrencyPrice_Active_5_days a ON MarketPriceRateID = p.OpenMarketPriceRateID AND a.InstrumentID = p.InstrumentID
)
ON OpenMarket_Ask IS NULL AND CAST(a.Occurred AS date) BETWEEN DATEADD(DAY, - 5, CAST(CAST(p.OpenDateID AS STRING) AS date)) AND CAST(CAST(p.OpenDateID AS STRING) AS date) and p.OpenDateID = CAST ( date_format(V_Yesterday, 'yyyyMMdd') AS INT ) -- this condition should join the only positions which are still null where MarketPriceRateID is found in the Ext table but not PriceRateID
 AND 
COALESCE(p.OpenMarketPriceRateID::string,'__NULL__') = COALESCE(p_TGT.OpenMarketPriceRateID::string,'__NULL__') AND 
COALESCE(p.InstrumentID::string,'__NULL__') = COALESCE(p_TGT.InstrumentID::string,'__NULL__') AND 
COALESCE(p.OpenDateID::string,'__NULL__') = COALESCE(p_TGT.OpenDateID::string,'__NULL__')
WHEN MATCHED THEN UPDATE SET
OpenMarket_Ask = a.Ask ,
OpenMarket_Bid = a.Bid ,
OpenMarket_AskSpreaded = a.AskSpreaded ,
OpenMarket_BidSpreaded = a.BidSpreaded ,
OpenMarketCoversionRateBidSpreaded = a.USDConversionRateBidSpreaded ,
OpenMarketCoversionRateAskSpreaded = a.USDConversionRateAskSpreaded;
		UPDATE dwh_daily_process.migration_tables.Dim_Position;
SET    OpenMarket_Ask            = InitForex_Ask
     , OpenMarket_Bid            = InitForex_Bid
     , OpenMarket_AskSpreaded    = InitForex_AskSpreaded
     , OpenMarket_BidSpreaded    = InitForex_BidSpreaded
WHERE OpenMarket_Ask IS NULL 
    AND InitForexPriceRateID = OpenMarketPriceRateID
    AND InitForex_Ask IS NOT null 
    AND OpenDateID=CAST(date_format(V_Yesterday, 'yyyyMMdd') AS INT)

;
END;
