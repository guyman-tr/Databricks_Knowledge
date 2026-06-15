WITH
SPLITRATIOS AS
(
    SELECT
        sr.InstrumentID,
        COALESCE(sr.MinDate, CAST('1900-01-01' AS TIMESTAMP)) AS MinDate,
        COALESCE(sr.MaxDate, CAST('2999-12-31' AS TIMESTAMP)) AS MaxDate,
        COALESCE(sr.PriceRatio, 1) AS PriceRatio,
        COALESCE(sr.AmountRatio, 1) AS AmountRatio
    FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_historysplitratio sr
),
-------------------------------------------------------------------------------------------------------------------
-- 2. POS (Replaces #POS)
-- Filters relevant positions.
-------------------------------------------------------------------------------------------------------------------
POS AS
(
    SELECT
        dp.PositionID
      , dp.CID
      , dp.InstrumentID
      , dp.Leverage
      , dp.Amount
      , dp.AmountInUnitsDecimal
      , dp.InitForexRate
      , dp.IsBuy
      , dp.OpenDateID
      , dp.CloseDateID
      , dp.OpenOccurred
      , dp.CloseOccurred
      , dp.IsPartialCloseParent
      , dp.IsPartialCloseChild
      , dp.InitialUnits
      , dp.SettlementTypeID
      , dp.InitConversionRate
      , dp.LastOpConversionRate
      , dp.HedgeServerID
    FROM main.dwh.dim_position dp
        JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument di
            ON dp.InstrumentID = di.InstrumentID AND di.InstrumentTypeID IN (5,6)
    WHERE 1 = 1
        -- Filter dates: Only positions open or closed after the cut-off
        AND dp.OpenDateID > 20251001 AND (dp.CloseDateID = 0 OR dp.CloseDateID > 20251001)
        AND dp.SettlementTypeID = 5
),
-------------------------------------------------------------------------------------------------------------------
-- 3. LATEST_HEDGE_SERVER
-- Gets the most recent hedge server change per position from the changelog.
-- If no change exists, the final SELECT falls back to the initial HedgeServerID from dim_position.
-------------------------------------------------------------------------------------------------------------------
LATEST_HEDGE_SERVER AS
(
    SELECT
        PositionID
      , FromHedgeServerID AS PreviousHedgeServerID
      , ToHedgeServerID AS LatestHedgeServerID
      , ADM_DATE AS HedgeServerChangeDate
    FROM (
        SELECT
            hs.PositionID
          , hs.FromHedgeServerID
          , hs.ToHedgeServerID
          , hs.ADM_DATE
          , ROW_NUMBER() OVER (PARTITION BY hs.PositionID ORDER BY hs.ADM_DATE DESC) AS rn
        FROM main.trading.bronze_etoro_trade_positionshedgeserverchangelog hs
            JOIN POS pos ON hs.PositionID = pos.PositionID
    ) ranked
    WHERE rn = 1
),
-------------------------------------------------------------------------------------------------------------------
-- 4. DATA_WITH_GROUPS (Replaces #DATA_WITH_GROUPS)
-- Creates the LKV_GroupID_Helper column using a running sum (LKV = Last Known Value).
-------------------------------------------------------------------------------------------------------------------
DATA_WITH_GROUPS AS
(
    SELECT
        dpcl.PositionID
      , dpcl.CID
      , dpcl.Occurred
      , dpcl.OccurredDateID
      , dpcl.ChangeTypeID
      , pos.InstrumentID
      , pos.HedgeServerID
      , CASE WHEN dpcl.ChangeTypeID = 0 THEN 0 ELSE dpcl.PreviousAmount END AS PreviousAmount
      , CASE WHEN dpcl.ChangeTypeID = 0 THEN dpcl.NewAmount
             WHEN dpcl.ChangeTypeID = 6 THEN -1 * dpcl.PreviousAmount
        ELSE dpcl.AmountChanged END AS AmountChanged
      , CASE WHEN dpcl.ChangeTypeID = 6 THEN 0 ELSE dpcl.NewAmount END AS NewAmount
      , CASE WHEN dpcl.ChangeTypeID = 0 THEN 0 ELSE dpcl.PreviousAmountInUnits END AS PreviousAmountInUnits
      , CASE WHEN dpcl.ChangeTypeID = 6 THEN 0 ELSE dpcl.AmountInUnits END AS AmountInUnits
      -- Creates the group ID (Increments only when AmountInUnits IS NOT NULL)
      , SUM(CASE WHEN dpcl.AmountInUnits IS NOT NULL THEN 1 ELSE 0 END)
            OVER (PARTITION BY dpcl.PositionID ORDER BY dpcl.Occurred) AS LKV_GroupID_Helper
      , pos.Leverage
      , pos.InitForexRate
      , pos.InitConversionRate
      , pos.OpenDateID
      , pos.CloseDateID
    FROM
        main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_positionchangelog dpcl
            JOIN POS pos
                ON dpcl.PositionID = pos.PositionID
    WHERE dpcl.ChangeTypeID IN (0,1,6,12)
),
-------------------------------------------------------------------------------------------------------------------
-- 5. LKV_IN_GROUP (Replaces #LKV_IN_GROUP)
-- Finds the last non-NULL AmountInUnits (LKV) within each island/group.
-------------------------------------------------------------------------------------------------------------------
LKV_IN_GROUP AS
(
    SELECT
        d.*,
        -- Inner Window Function: Find the last non-NULL AmountInUnits within the island.
        MAX(d.AmountInUnits)
        OVER (
            PARTITION BY d.PositionID, d.LKV_GroupID_Helper
            ORDER BY d.Occurred
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS LastKnownAmountInUnits_InGroup
    FROM
        DATA_WITH_GROUPS d
),
-------------------------------------------------------------------------------------------------------------------
-- 6. FINALPREP (Replaces #FINALPREP)
-- Adds LAG calculations for PreviousAmountInUnits and its change.
-------------------------------------------------------------------------------------------------------------------
FINALPREP AS
(
    SELECT
        l.PositionID
      , l.InstrumentID
      , l.CID
      , l.Occurred
      , l.OccurredDateID
      , l.ChangeTypeID
      , l.PreviousAmount
      , l.AmountChanged
      , l.NewAmount
      , l.LastKnownAmountInUnits_InGroup AS AmountInUnits
      , l.Leverage
      , l.InitForexRate
      , l.InitConversionRate
      , l.OpenDateID
      , l.CloseDateID
      , l.HedgeServerID
      , COALESCE(
            LAG(l.LastKnownAmountInUnits_InGroup, 1, 0)
            OVER (PARTITION BY l.PositionID ORDER BY l.Occurred),
            0
        ) AS PreviousAmountInUnits
      , l.LastKnownAmountInUnits_InGroup - COALESCE(LAG(l.LastKnownAmountInUnits_InGroup, 1, 0) OVER (PARTITION BY l.PositionID ORDER BY l.Occurred), 0) AS AmountInUnitsChange
    FROM
        LKV_IN_GROUP l
),
-------------------------------------------------------------------------------------------------------------------
-- 7. AMOUNTPREP_RAW (Replaces #AMOUNTPREP_RAW)
-- Joins with SplitRatios, calculates Split-Adjusted Units, and generates Row Numbers.
-------------------------------------------------------------------------------------------------------------------
AMOUNTPREP_RAW AS
(
    SELECT
        dpcl.PositionID
      , dpcl.CID
      , dpcl.InstrumentID
      , dpcl.Occurred
      , dpcl.OccurredDateID
      , dpcl.ChangeTypeID
      , dpcl.PreviousAmount
      , dpcl.AmountChanged
      , dpcl.NewAmount
      , CAST(dpcl.PreviousAmountInUnits * sr.AmountRatio AS FLOAT) AS PreviousAmountInUnitsSplitAdjusted
      , CAST(dpcl.AmountInUnits * sr.AmountRatio AS FLOAT) AS AmountInUnitsSplitAdjusted
      , ROW_NUMBER() OVER (PARTITION BY dpcl.PositionID ORDER BY dpcl.Occurred) AS RN_ASC
      , ROW_NUMBER() OVER (PARTITION BY dpcl.PositionID ORDER BY dpcl.Occurred DESC) AS RN_DESC
      , dpcl.Leverage
      , dpcl.InitForexRate
      , dpcl.InitConversionRate
      , dpcl.OpenDateID
      , dpcl.CloseDateID
      , dpcl.HedgeServerID
    FROM FINALPREP dpcl
        LEFT JOIN SPLITRATIOS sr
            ON dpcl.InstrumentID = sr.InstrumentID AND dpcl.Occurred BETWEEN sr.MinDate AND sr.MaxDate
),
-------------------------------------------------------------------------------------------------------------------
-- 8. AMOUNTPREP (Replaces #AMOUNTPREP)
-- Calculates Adjusted Amounts, Running Totals, and final adjusted unit/amount values.
-------------------------------------------------------------------------------------------------------------------
AMOUNTPREP AS
(
 SELECT
    CASE WHEN a.ChangeTypeID = 0  THEN 'Open'
         WHEN a.ChangeTypeID = 6  THEN 'Close'
         WHEN a.ChangeTypeID = 1  THEN 'EditSLs'
         WHEN a.ChangeTypeID = 12 THEN 'PartialClose'
    ELSE 'NA' END AS EventType
  , a.PositionID
  , a.InstrumentID
  , a.CID
  , a.Occurred
  , a.OccurredDateID
  , a.ChangeTypeID
  , a.RN_ASC
  , a.RN_DESC
  , a.Leverage
  , a.InitForexRate
  , a.InitConversionRate
  , a.OpenDateID
  , a.CloseDateID
  , a.PreviousAmountInUnitsSplitAdjusted
  , a.AmountInUnitsSplitAdjusted
  , a.HedgeServerID
  , CASE WHEN a.RN_ASC = 1 AND a.ChangeTypeID = 0 THEN 0 ELSE a.PreviousAmount END AS PreviousAmountAdj
  , CASE WHEN a.RN_DESC = 1 AND a.ChangeTypeID = 6 THEN 0 ELSE a.NewAmount END AS NewAmountAdj
  -- Define AmountChange
  , (CASE WHEN a.RN_DESC = 1 AND a.ChangeTypeID = 6 THEN 0 ELSE a.NewAmount END) -
    (CASE WHEN a.RN_ASC = 1 AND a.ChangeTypeID = 0 THEN 0 ELSE a.PreviousAmount END) AS AmountChange
  -- Calculate running total of AmountChange
  , SUM(
    (CASE WHEN a.RN_DESC = 1 AND a.ChangeTypeID = 6 THEN 0 ELSE a.NewAmount END) -
    (CASE WHEN a.RN_ASC = 1 AND a.ChangeTypeID = 0 THEN 0 ELSE a.PreviousAmount END)
    ) OVER (PARTITION BY a.PositionID ORDER BY a.Occurred ROWS UNBOUNDED PRECEDING) AS RunningTotalAmountChange
  , CASE WHEN a.RN_ASC = 1 AND a.ChangeTypeID = 0 THEN 0 ELSE COALESCE(a.PreviousAmountInUnitsSplitAdjusted, 0) END AS PreviousAmountInUnitsAdj
  , CASE WHEN a.RN_DESC = 1 AND a.ChangeTypeID = 6 THEN 0 ELSE COALESCE(a.AmountInUnitsSplitAdjusted, 0) END AS NewAmountInUnitsAdj
  -- Define AmountInUnitsChange
  , (CASE WHEN a.RN_DESC = 1 AND a.ChangeTypeID = 6 THEN 0 ELSE COALESCE(a.AmountInUnitsSplitAdjusted, 0) END) -
    (CASE WHEN a.RN_ASC = 1 AND a.ChangeTypeID = 0 THEN 0 ELSE COALESCE(a.PreviousAmountInUnitsSplitAdjusted, 0) END) AS AmountInUnitsChange
  -- Calculate running total of AmountInUnitsChange
  , SUM(
    (CASE WHEN a.RN_DESC = 1 AND a.ChangeTypeID = 6 THEN 0 ELSE COALESCE(a.AmountInUnitsSplitAdjusted, 0) END) -
    (CASE WHEN a.RN_ASC = 1 AND a.ChangeTypeID = 0 THEN 0 ELSE COALESCE(a.PreviousAmountInUnitsSplitAdjusted, 0) END)
    ) OVER (PARTITION BY a.PositionID ORDER BY a.Occurred ROWS UNBOUNDED PRECEDING) AS RunningTotalAmountInUnitsChange
    FROM AMOUNTPREP_RAW a
)
-------------------------------------------------------------------------------------------------------------------
-- 9. FINAL SELECT (Output)
-------------------------------------------------------------------------------------------------------------------
SELECT
    ap.*
  , ap.InitForexRate * ap.PreviousAmountInUnitsAdj * ap.InitConversionRate - ap.PreviousAmountAdj AS PreviousLoanValue
  , ap.InitForexRate * ap.NewAmountInUnitsAdj * ap.InitConversionRate - ap.NewAmountAdj AS NewLoanValue
  , (ap.InitForexRate * ap.NewAmountInUnitsAdj * ap.InitConversionRate - ap.NewAmountAdj) -
        (ap.InitForexRate * ap.PreviousAmountInUnitsAdj * ap.InitConversionRate - ap.PreviousAmountAdj) AS LoanValueChange
  , COALESCE(lhs.PreviousHedgeServerID, ap.HedgeServerID) as PreviousHedgeServerID
  , COALESCE(lhs.LatestHedgeServerID, ap.HedgeServerID) AS CurrentHedgeServerID
  , lhs.HedgeServerChangeDate
  	, di.Symbol
	, dr1.Name AS Regulation
	, dc.Name AS Country
, IsCreditReportValidCB
FROM AMOUNTPREP ap
  LEFT JOIN LATEST_HEDGE_SERVER lhs
    ON ap.PositionID = lhs.PositionID
join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument di 
on ap.InstrumentID = di.InstrumentID
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked fsc
	ON ap.CID = fsc.RealCID
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range dr
	ON fsc.DateRangeID = dr.DateRangeID AND ap.OccurredDateID BETWEEN dr.FromDateID AND dr.ToDateID
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation dr1
	ON fsc.RegulationID = dr1.DWHRegulationID
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country dc
	ON fsc.CountryID = dc.CountryID