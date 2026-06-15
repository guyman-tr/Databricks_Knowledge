USE CATALOG dwh_daily_process;
USE SCHEMA migration_tables;



CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.SP_Fact_Position_Futures_Snapshot(
IN V_dt TIMESTAMP)
LANGUAGE SQL
SQL SECURITY INVOKER
MODIFIES SQL DATA
AS

BEGIN


DECLARE V_dtID int ;

DECLARE V_dtPrev DATE ;

DECLARE V_dtPrevID int ;
-- =============================================
-- Author:      <Guy Manova>
-- Create Date: 2024-11-11
-- Description: SP intended to insert data to Fact_Position_Futures_Snapshot
-- exec [DWH_dbo].[SP_Fact_Position_Futures_Snapshot] '20250105'
-- =============================================
/***************************
** Change History
**************************
Date			Author			Ticket #		Description   
----------		----------		----------		------------------------------------
2024-12-31		Inbal BML						Add #Fact_Settlement_Prices_LastPrices
2025-01-08		Inbal BML						Alter #Fact_Settlement_Prices_LastPrices
2025-01-20		Guy M			#SR-293809		added some changes after QA of actual data and better knowledge of what the finance report will look like
2025-08-12		Guy M			#SR-327197		switched a couple of joins to left joins, as there are contant market data failures to bring some settlement prices causing lost rows. 

--**********************************************************************************************************************/

  

-- DECLARE @dt DATE = '20250812'

SET V_dtID = CAST(date_format(V_dt, 'yyyyMMdd') AS INT)
;
SET V_dtPrev = DATEADD(DAY, -1, V_dt)
;
SET V_dtPrevID = CAST(date_format(V_dt, 'yyyyMMdd') AS INT);
/*
#Fact_Settlement_Prices_LastPrices
Because not every day there are prices so we need first to select the latest price for each InstrumentID
*/

DROP VIEW IF EXISTS TEMP_TABLE_Fact_Settlement_Prices_LastPrices;
CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_Fact_Settlement_Prices_LastPrices
    
AS 
SELECT InstrumentID
       ,SettlementDateID	
	   ,SettlementDate	
	   ,SettlementPrice	
	   ,UpdateDate
from (
		SELECT  * , ROW_NUMBER () over(partition by InstrumentID order by SettlementDate desc) RN
		FROM dwh_daily_process.migration_tables.Fact_Settlement_Prices
		where SettlementDate <= V_dt and SettlementDate > DATEADD(day, -14, V_dt)
		      ) fsp
where RN=1;

 --select * from  #Fact_Settlement_Prices_LastPrices order by InstrumentID
-- [stub] debug SELECT with unterminated string elided

/*****************************************************************************************************
full population of positions for the daily snapshot: still open at settlement time every day or closed between 
pervios settlement and current settlement
*****************************************************************************************************/

/*
for open positions, just like in PositionPnL, we will need to reconstruct the position data 
at the time of the settlement
*/
DROP VIEW IF EXISTS TEMP_TABLE_openAtSettlement;
CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_openAtSettlement
    
AS
SELECT  V_dt AS Date
	  , V_dtID AS DateID
	  , 'OpenAtSettlement' AS SettlementCategory
	  , dp.CID
	  , dp.PositionID
	  , dp.OriginalPositionID
	  , dp.InstrumentID
	  , dp.LotCountDecimal
	  , dis.SettlementTime
	  , fsp.SettlementPrice 
	  , dp.Amount AS InvestedAmount
	  , dp.OpenOccurred
	  , '1900-01-01 00:00:00.000' AS CloseOccurred
	  , dp.InitForexRate
	  , NULL AS EndForexRate
	  , NULL AS IsPartialCloseParent 
	  , 0 AS IsPartialCloseChild
	  , dp.IsBuy
	  , dis.ProviderID
	  , dis.Multiplier
	  , NULL AS ProviderMargin -- usually will not change but to be on the safe side we'll also use changelogs
	  , NULL AS eToroMargin -- usually will not change but to be on the safe side we'll also use changelogs
	  , cast(NULL as DECIMAL(19,4)) AS PnL -- we need to compute based on steelement price and position status at settlement time
FROM dwh_daily_process.migration_tables.Dim_Position dp
JOIN dwh_daily_process.migration_tables.Dim_Instrument_Snapshot dis 
	ON dp.InstrumentID = dis.InstrumentID AND dis.DateID  = V_dtID AND dis.IsFuture = 1
LEFT JOIN  TEMP_TABLE_Fact_Settlement_Prices_LastPrices fsp  -- guym 2025-08-12
	ON dp.InstrumentID = fsp.InstrumentID --AND fsp.SettlementDateID = @dtID
WHERE (dp.CloseOccurred > dis.SettlementTime OR dp.CloseOccurred = 0) AND dp.OpenOccurred <= dis.SettlementTime and dis.IsFuture=1 
	AND COALESCE(dp.IsPartialCloseChild, 0) = 0; -- guym 2025-01-19 - closed child positions which closed


/*  select * from [DWH_dbo].[Dim_Instrument_Snapshot]
for closed positions its easier, we just need to know end state of metrics which are not in DimPosition, the rest from there
*/

-- closed between  yesterday's settlement and todays settlement timestamps
DROP VIEW IF EXISTS TEMP_TABLE_ClosedInSettlement;
CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_ClosedInSettlement
    
AS
SELECT V_dt AS Date
	  , V_dtID AS DateID
	  , 'ClosedBeforeSettlement' AS SettlementCategory
	  , dp.CID
	  , dp.PositionID
	  , dp.OriginalPositionID
	  , dp.InstrumentID
	  , dp.LotCountDecimal
	  , dis.SettlementTime
	  , fsp.SettlementPrice
	  , dp.Amount AS InvestedAmount
	  , dp.OpenOccurred
	  , dp.CloseOccurred 
	  , dp.InitForexRate
	  , dp.EndForexRate
	  , dp.IsPartialCloseParent
	  , dp.IsPartialCloseChild
	  , dp.IsBuy
	  , dis.ProviderID
	  , dis.Multiplier
	  , NULL AS ProviderMargin
	  , NULL AS eToroMargin
	  , dp.NetProfit AS PnL
FROM dwh_daily_process.migration_tables.Dim_Position dp
JOIN dwh_daily_process.migration_tables.Dim_Instrument_Snapshot dis 
	ON dp.InstrumentID = dis.InstrumentID AND dis.DateID  = V_dtID AND dis.IsFuture = 1
LEFT JOIN  TEMP_TABLE_Fact_Settlement_Prices_LastPrices fsp -- guym 2025-08-12
	ON dp.InstrumentID = fsp.InstrumentID -- AND fsp.SettlementDateID = @dtID
WHERE dp.CloseOccurred > DATEADD(DAY, -1, dis.SettlementTime) AND dp.CloseOccurred <= dis.SettlementTime and dis.IsFuture=1;

--WHERE dp.CloseOccurred > @settlementTimePrev AND dp.CloseOccurred <= @settlementTime


/*****************************************************************************************************
find the original state of some position metrics (lot count, margins, invested amounts, partial status)
*****************************************************************************************************/

-- all positions (to fetch changloegs for)
DROP VIEW IF EXISTS TEMP_TABLE_allPos -- select * from #allPos where PositionID = 2316424660
;
CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_allPos
    
AS
SELECT PositionID, DateID
FROM TEMP_TABLE_openAtSettlement 
UNION 
SELECT PositionID , DateID
FROM TEMP_TABLE_ClosedInSettlement cis


;
DROP VIEW IF EXISTS TEMP_TABLE_changelog -- 
;
CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_changelog
    
AS
SELECT
	dpcl.PositionID
  , dpcl.Occurred
  , dpcl.OccurredDateID
  , dpcl.ChangeTypeID
  , dpcl.PreviousAmount
  , dpcl.AmountChanged
  , dpcl.NewAmount
  , dpcl.PreviousAmountInUnits 
  , dpcl.AmountInUnits
  , dpcl.PreviousLotCountDecimal AS PreviousLotCountDecimal -- guym 2024-11-20
  , dpcl.LotCountDecimal AS NewLotCountDecimal -- guym 2024-11-20
  , ROW_NUMBER () OVER (PARTITION BY dpcl.PositionID, dpcl.ChangeTypeID ORDER BY dpcl.Occurred) AS RN
FROM dwh_daily_process.migration_tables.Dim_PositionChangeLog dpcl
WHERE dpcl.OccurredDateID <= V_dtID
AND dpcl.ChangeTypeID IN (1,12,0,11) -- guym 2025-01-19 added opens (0) and partial close children (11)
AND dpcl.PositionID IN (SELECT PositionID FROM TEMP_TABLE_allPos)


 ;
-- [stub] debug SELECT with unterminated string elided

-- step 1: find the original metrics at open
DROP VIEW IF EXISTS TEMP_TABLE_originMetrics ;
CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_originMetrics
    
AS
SELECT distinct
	cl.PositionID
  , cl.NewLotCountDecimal AS InitialLotCountDecimal -- guym 2025-01-19
  , cl.NewAmount AS InitialInvestedAmount
  , dis.ProviderMarginPerLot AS InitialProviderMarginPerLot
  , dis.eToroMarginPerLot AS InitialeToroMarginPerLot
  , cl.NewLotCountDecimal * dis.ProviderMarginPerLot AS InitialProviderMargin
  , cl.NewLotCountDecimal * dis.eToroMarginPerLot AS InitialeToroMargin
FROM TEMP_TABLE_allPos p 
JOIN TEMP_TABLE_changelog  cl
	ON p.PositionID = cl.PositionID AND cl.ChangeTypeID = 0
JOIN dwh_daily_process.migration_tables.Dim_Position dp
	ON cl.PositionID = dp.PositionID
LEFT JOIN dwh_daily_process.migration_tables.Dim_Instrument_Snapshot dis 
	ON dp.InstrumentID = dis.InstrumentID AND cast(dp.OpenOccurred AS DATE) = cast(dis.SettlementTime AS DATE) AND dis.IsFuture = 1

 ;
-- [stub] debug SELECT with unterminated string elided

-- step 2: find out when was the first occurrance a partial close on the position occurred
DROP VIEW IF EXISTS TEMP_TABLE_firstPartial;
CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_firstPartial
    
AS
SELECT c.PositionID, c.Occurred, c.OccurredDateID, c.PreviousLotCountDecimal AS InitialLotCountDecimal -- guym 2024-11-19
FROM TEMP_TABLE_changelog c
WHERE c.ChangeTypeID = 12 
AND c.RN = 1;

-- step 3: update the true initial lot count at open

 MERGE INTO t1 A_TGT -- guym 2024-11-19

USING (
SELECT * 
FROM TEMP_TABLE_originMetrics t1
INNER JOIN TEMP_TABLE_firstPartial t2 ON t1.PositionID = t2.PositionID /*************************************
update the positions with correct data 
*************************************/
 -- open positions need to update the previous LotCount, InvestedAmount, and whether its really a Parent or not
 -- step 4: update a bunch of metrics accoriding to the changelog at the time of settlement


QUALIFY ROW_NUMBER() OVER (PARTITION BY t1.PositionID ORDER BY 1) = 1
)
ON t1.PositionID = A_TGT.PositionID
WHEN MATCHED THEN UPDATE SET
t1.InitialLotCountDecimal = t2.InitialLotCountDecimal;
 MERGE INTO TEMP_TABLE_openAtSettlement t1_TGT
USING (
SELECT * 
FROM TEMP_TABLE_openAtSettlement t1 LEFT JOIN LATERAL ( --last action of position before SettlementTime -- SELECT * FROM #changelog b WHERE PositionID = 2908037488  ORDER BY b.Occurred desc
 SELECT * FROM TEMP_TABLE_changelog b WHERE t1.PositionID = b.PositionID AND b.Occurred <= t1.SettlementTime AND b.ChangeTypeID = 12 ORDER BY b.Occurred desc ) t2 ON true LEFT JOIN LATERAL ---why need top 1???
 ( SELECT * FROM TEMP_TABLE_firstPartial b WHERE t1.PositionID = b.PositionID AND b.Occurred <= t1.SettlementTime ORDER BY b.Occurred desc ) t3 ON true LEFT JOIN LATERAL ( --last action of position before SettlementTime -- SELECT * FROM #changelog b WHERE PositionID = 2908037488  ORDER BY b.Occurred desc
 SELECT * FROM TEMP_TABLE_changelog b WHERE t1.PositionID = b.PositionID AND b.Occurred <= t1.SettlementTime AND b.ChangeTypeID = 1 ORDER BY b.Occurred desc ) t4 ON true
LEFT JOIN TEMP_TABLE_changelog t5 ON t1.PositionID = t5.PositionID AND t5.ChangeTypeID = 0
)
ON 
COALESCE(t1.LotCountDecimal::string,'__NULL__') = COALESCE(t1_TGT.LotCountDecimal::string,'__NULL__') AND 
COALESCE(t1.InvestedAmount::string,'__NULL__') = COALESCE(t1_TGT.InvestedAmount::string,'__NULL__') AND 
COALESCE(t1.PositionID::string,'__NULL__') = COALESCE(t1_TGT.PositionID::string,'__NULL__') AND 
COALESCE(t1.SettlementTime::string,'__NULL__') = COALESCE(t1_TGT.SettlementTime::string,'__NULL__')
WHEN MATCHED THEN UPDATE SET
LotCountDecimal = COALESCE ( t1.LotCountDecimal , t2.NewLotCountDecimal , t5.NewLotCountDecimal ) ,
InvestedAmount = COALESCE ( t1.InvestedAmount , t4.NewAmount , t5.NewAmount ) ,
IsPartialCloseParent = CASE WHEN t3.PositionID IS NOT NULL THEN 1 ELSE 0 END;
 MERGE INTO t1 -- only the lot count is not correct on the closing positions, compare logs to close time

USING TEMP_TABLE_ClosedInSettlement t1 LEFT JOIN LATERAL(SELECT  * FROM TEMP_TABLE_changelog b WHERE t1.PositionID = b.PositionID AND b.Occurred <= t1.CloseOccurred AND b.ChangeTypeID = 11 ORDER BY b.Occurred desc
limit 1) t2 ON true -- step 5: mark to market the PnL based on settlement price and actual lot count 

ON 1 = 1
WHEN MATCHED THEN UPDATE SET
LotCountDecimal = CASE WHEN t2.PositionID IS NULL THEN t1.LotCountDecimal else t2.NewLotCountDecimal END;
UPDATE TEMP_TABLE_openAtSettlement SET PnL = (LotCountDecimal * Multiplier * SettlementPrice) - (LotCountDecimal * Multiplier * InitForexRate);
-- step 6: update the correct state of the partial parent/child as of the settlement time
UPDATE TEMP_TABLE_openAtSettlement
SET IsPartialCloseParent = 0 WHERE IsPartialCloseParent IS NULL
;
UPDATE TEMP_TABLE_openAtSettlement
SET IsPartialCloseChild = 0 WHERE IsPartialCloseChild IS NULL
;
UPDATE TEMP_TABLE_openAtSettlement
SET OriginalPositionID = PositionID WHERE IsPartialCloseChild = 0
;
UPDATE TEMP_TABLE_ClosedInSettlement
SET IsPartialCloseParent = 0 WHERE IsPartialCloseParent IS NULL
;
UPDATE TEMP_TABLE_ClosedInSettlement
SET IsPartialCloseChild = 0 WHERE IsPartialCloseChild IS NULL
;
UPDATE TEMP_TABLE_ClosedInSettlement
SET OriginalPositionID = PositionID WHERE IsPartialCloseChild = 0

 ;
-- [stub] debug SELECT with unterminated string elided


 --- final preps: add the initial full and initial residual (metrics per lot can change - we will need to original metrics as well)
DROP VIEW IF EXISTS TEMP_TABLE_prepOpens;
CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_prepOpens
    
AS
SELECT oas.Date
	 , oas.DateID
	 , oas.SettlementCategory
	 , oas.CID
	 , oas.PositionID
	 , oas.OriginalPositionID
	 , oas.InstrumentID
	 , oas.LotCountDecimal
	 , oas.SettlementTime
	 , oas.SettlementPrice
	 , oas.InvestedAmount
	 , oas.OpenOccurred
	 , oas.CloseOccurred
	 , oas.InitForexRate
	 , oas.EndForexRate
	 , COALESCE(oas.IsPartialCloseParent, 0) AS IsPartialCloseParent
	 , COALESCE(oas.IsPartialCloseChild, 0) AS IsPartialCloseChild
	 , oas.IsBuy
	 , oas.ProviderID
	 , oas.Multiplier
	 , oas.LotCountDecimal * dis.ProviderMarginPerLot AS ProviderMargin
	 , oas.LotCountDecimal * dis.eToroMarginPerLot AS eToroMargin
	 , oas.PnL
	 , m.InitialLotCountDecimal AS InitialLotCountDecimalFull
	 , m.InitialInvestedAmount AS InitialInvestedAmountFull
	 , m.InitialProviderMarginPerLot * m.InitialLotCountDecimal AS InitialProviderMarginFull
	 , m.InitialeToroMarginPerLot * m.InitialLotCountDecimal AS InitialeToroMarginFull
	 , oas.LotCountDecimal AS InitialLotCountDecimalResidual
	 , m.InitialInvestedAmount * oas.LotCountDecimal / m.InitialLotCountDecimal AS InitialInvestedAmountResidual
	 , m.InitialProviderMarginPerLot * oas.LotCountDecimal AS InitialProviderMarginResidual
	 , m.InitialeToroMarginPerLot * oas.LotCountDecimal AS InitialeToroMarginResidual
	 , current_timestamp() as UpdateDate
FROM TEMP_TABLE_openAtSettlement oas 
LEFT JOIN dwh_daily_process.migration_tables.Dim_Instrument_Snapshot dis 
	ON oas.InstrumentID = dis.InstrumentID
		AND oas.SettlementTime = dis.SettlementTime 
LEFT JOIN TEMP_TABLE_originMetrics m			
	ON oas.PositionID = m.PositionID 


 ;
-- [stub] debug SELECT with unterminated string elided
UPDATE TEMP_TABLE_prepOpens
SET OriginalPositionID = PositionID 
WHERE OriginalPositionID IS NULL 
	AND IsPartialCloseChild = 0


;
DROP VIEW IF EXISTS TEMP_TABLE_prepClosed;
CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_prepClosed
    
AS
SELECT oas.Date
	 , oas.DateID
	 , oas.SettlementCategory
	 , oas.CID
	 , oas.PositionID
	 , oas.OriginalPositionID
	 , oas.InstrumentID
	 , oas.LotCountDecimal
	 , oas.SettlementTime
	 , oas.SettlementPrice
	 , oas.InvestedAmount
	 , oas.OpenOccurred
	 , oas.CloseOccurred
	 , oas.InitForexRate
	 , oas.EndForexRate
	 , COALESCE(oas.IsPartialCloseParent, 0) AS IsPartialCloseParent
	 , COALESCE(oas.IsPartialCloseChild, 0) AS IsPartialCloseChild
	 , oas.IsBuy
	 , oas.ProviderID
	 , oas.Multiplier
	 , oas.LotCountDecimal * dis.ProviderMarginPerLot AS ProviderMargin
	 , oas.LotCountDecimal * dis.eToroMarginPerLot AS eToroMargin
	 , oas.PnL
	 , m.InitialLotCountDecimal AS InitialLotCountDecimalFull 
	 , m.InitialInvestedAmount AS InitialInvestedAmountFull
	 , m.InitialProviderMarginPerLot * m.InitialLotCountDecimal  AS InitialProviderMarginFull
	 , m.InitialeToroMarginPerLot * m.InitialLotCountDecimal   AS InitialeToroMarginFull
	 , oas.LotCountDecimal AS InitialLotCountDecimalResidual -- m.InitialLotCountDecimal 
	 , m.InitialInvestedAmount * oas.LotCountDecimal / m.InitialLotCountDecimal AS InitialInvestedAmountResidual
	 , m.InitialProviderMarginPerLot * oas.LotCountDecimal  AS InitialProviderMarginResidual
	 , m.InitialeToroMarginPerLot * oas.LotCountDecimal   AS InitialeToroMarginResidual
	 , current_timestamp() as UpdateDate
FROM TEMP_TABLE_ClosedInSettlement oas 
LEFT JOIN dwh_daily_process.migration_tables.Dim_Instrument_Snapshot dis 
	ON oas.InstrumentID = dis.InstrumentID
		AND oas.DateID = dis.DateID 
LEFT JOIN TEMP_TABLE_originMetrics m			
	ON oas.OriginalPositionID = m.PositionID;


UPDATE TEMP_TABLE_prepClosed
SET OriginalPositionID = PositionID 
WHERE OriginalPositionID IS NULL 
	AND IsPartialCloseChild = 0


;
-- [stub] debug SELECT with unterminated string elided



DELETE FROM dwh_daily_process.migration_tables.Fact_Position_Futures_Snapshot WHERE DateID = V_dtID

;
INSERT INTO dwh_daily_process.migration_tables.Fact_Position_Futures_Snapshot
SELECT * FROM TEMP_TABLE_prepOpens o
UNION ALL SELECT * FROM TEMP_TABLE_prepClosed c

;
END;
