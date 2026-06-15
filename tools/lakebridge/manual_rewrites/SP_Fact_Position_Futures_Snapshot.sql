-- Manual rewrite of DWH_dbo.SP_Fact_Position_Futures_Snapshot
-- Source author: Guy Manova, 2024-11-11.
--
-- Why this needed a rewrite:
--   The original is heavily T-SQL-imperative: it builds a chain of
--   `CREATE TABLE #tmp` staging tables and then MUTATES them via
--   `MERGE INTO #tmp` / `UPDATE #tmp`. Databricks SQL has neither
--   `CREATE TEMPORARY TABLE`-with-DDL nor `MERGE INTO <temp view>`,
--   so a 1:1 translation is impossible.
--
-- Strategy: convert every mutating step into an additional layer of
-- `CREATE OR REPLACE TEMPORARY VIEW`. Each "update" is baked into the
-- next view's SELECT as a LEFT JOIN + COALESCE. The final fact rows
-- are computed in one INSERT off the chain.
--
-- Step layout (mirrors the original comments):
--   v_last_prices            : latest settlement price per instrument (14d window).
--   v_open_base              : open positions snapshot @ settlement.
--   v_closed_base            : positions closed within the settlement window.
--   v_all_pos                : UNION of position IDs from open + closed.
--   v_changelog              : filtered Dim_PositionChangeLog for those positions.
--   v_origin_metrics_raw     : initial-open metrics (ChangeTypeID=0).
--   v_first_partial          : first partial-close per position (ChangeTypeID=12, RN=1).
--   v_origin_metrics         : raw origin overlaid with first-partial PreviousLotCount.
--   v_last_12_open           : latest partial-close before SettlementTime per open pos.
--   v_last_1_open            : latest amount-change before SettlementTime per open pos.
--   v_open_t5                : the ChangeTypeID=0 row per position (for fallbacks).
--   v_last_11_closed         : latest partial-child before CloseOccurred per closed pos.
--   v_open_final             : open_base + lookups -> corrected LotCount / Invested / Parent.
--   v_closed_final           : closed_base + lookups -> corrected LotCount.
--   v_prep_opens             : final wide row for opens.
--   v_prep_closed            : final wide row for closed.
--   DELETE + INSERT          : idempotent reload for DateID.

CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.SP_Fact_Position_Futures_Snapshot(
    IN V_dt TIMESTAMP
)
LANGUAGE SQL
SQL SECURITY INVOKER
MODIFIES SQL DATA
AS
BEGIN
    DECLARE V_dtID INT;

    SET V_dtID = CAST(date_format(V_dt, 'yyyyMMdd') AS INT);

    -- ------------------------------------------------------------------
    -- (1) Latest settlement price per instrument in the last 14 days.
    -- Settlement data is sparse, so we don't assume V_dt itself has prices.
    -- ------------------------------------------------------------------
    CREATE OR REPLACE TEMPORARY VIEW v_last_prices AS
    SELECT InstrumentID,
           SettlementDateID,
           SettlementDate,
           SettlementPrice,
           UpdateDate
    FROM (
        SELECT fsp.*,
               ROW_NUMBER() OVER (
                   PARTITION BY InstrumentID
                   ORDER BY SettlementDate DESC
               ) AS RN
        FROM dwh_daily_process.migration_tables.Fact_Settlement_Prices fsp
        WHERE SettlementDate <= V_dt
          AND SettlementDate >  DATEADD(DAY, -14, V_dt)
    ) ranked
    WHERE RN = 1;

    -- ------------------------------------------------------------------
    -- (2) Positions OPEN at settlement (one row per future instrument).
    -- ------------------------------------------------------------------
    CREATE OR REPLACE TEMPORARY VIEW v_open_base AS
    SELECT V_dt                        AS RunDate,
           V_dtID                      AS DateID,
           'OpenAtSettlement'          AS SettlementCategory,
           dp.CID,
           dp.PositionID,
           dp.OriginalPositionID,
           dp.InstrumentID,
           dp.LotCountDecimal,
           dis.SettlementTime,
           fsp.SettlementPrice,
           dp.Amount                   AS InvestedAmount,
           dp.OpenOccurred,
           CAST('1900-01-01 00:00:00.000' AS TIMESTAMP) AS CloseOccurred,
           dp.InitForexRate,
           CAST(NULL AS DECIMAL(19,4)) AS EndForexRate,
           CAST(NULL AS INT)           AS IsPartialCloseParent,
           0                           AS IsPartialCloseChild,
           dp.IsBuy,
           dis.ProviderID,
           dis.Multiplier,
           CAST(NULL AS DECIMAL(19,4)) AS ProviderMargin,
           CAST(NULL AS DECIMAL(19,4)) AS eToroMargin,
           CAST(NULL AS DECIMAL(19,4)) AS PnL
    FROM dwh_daily_process.migration_tables.Dim_Position dp
    JOIN dwh_daily_process.migration_tables.Dim_Instrument_Snapshot dis
      ON dp.InstrumentID = dis.InstrumentID
     AND dis.DateID      = V_dtID
     AND dis.IsFuture    = 1
    LEFT JOIN v_last_prices fsp
      ON dp.InstrumentID = fsp.InstrumentID
    WHERE (dp.CloseOccurred > dis.SettlementTime OR dp.CloseOccurred = CAST('1900-01-01' AS TIMESTAMP))
      AND dp.OpenOccurred <= dis.SettlementTime
      AND dis.IsFuture = 1
      AND COALESCE(dp.IsPartialCloseChild, 0) = 0;

    -- ------------------------------------------------------------------
    -- (3) Positions CLOSED between previous settlement and current.
    -- ------------------------------------------------------------------
    CREATE OR REPLACE TEMPORARY VIEW v_closed_base AS
    SELECT V_dt                          AS RunDate,
           V_dtID                        AS DateID,
           'ClosedBeforeSettlement'      AS SettlementCategory,
           dp.CID,
           dp.PositionID,
           dp.OriginalPositionID,
           dp.InstrumentID,
           dp.LotCountDecimal,
           dis.SettlementTime,
           fsp.SettlementPrice,
           dp.Amount                     AS InvestedAmount,
           dp.OpenOccurred,
           dp.CloseOccurred,
           dp.InitForexRate,
           dp.EndForexRate,
           dp.IsPartialCloseParent,
           dp.IsPartialCloseChild,
           dp.IsBuy,
           dis.ProviderID,
           dis.Multiplier,
           CAST(NULL AS DECIMAL(19,4))   AS ProviderMargin,
           CAST(NULL AS DECIMAL(19,4))   AS eToroMargin,
           dp.NetProfit                  AS PnL
    FROM dwh_daily_process.migration_tables.Dim_Position dp
    JOIN dwh_daily_process.migration_tables.Dim_Instrument_Snapshot dis
      ON dp.InstrumentID = dis.InstrumentID
     AND dis.DateID      = V_dtID
     AND dis.IsFuture    = 1
    LEFT JOIN v_last_prices fsp
      ON dp.InstrumentID = fsp.InstrumentID
    WHERE dp.CloseOccurred >  DATEADD(DAY, -1, dis.SettlementTime)
      AND dp.CloseOccurred <= dis.SettlementTime
      AND dis.IsFuture     = 1;

    -- ------------------------------------------------------------------
    -- (4) Union of position IDs we need changelog rows for.
    -- ------------------------------------------------------------------
    CREATE OR REPLACE TEMPORARY VIEW v_all_pos AS
    SELECT PositionID, DateID FROM v_open_base
    UNION
    SELECT PositionID, DateID FROM v_closed_base;

    -- ------------------------------------------------------------------
    -- (5) Filtered change log. ChangeTypeID semantics in this codebase:
    --      0  = position open
    --      1  = amount change
    --     11  = partial close child
    --     12  = partial close (parent side)
    -- ------------------------------------------------------------------
    CREATE OR REPLACE TEMPORARY VIEW v_changelog AS
    SELECT dpcl.PositionID,
           dpcl.Occurred,
           dpcl.OccurredDateID,
           dpcl.ChangeTypeID,
           dpcl.PreviousAmount,
           dpcl.AmountChanged,
           dpcl.NewAmount,
           dpcl.PreviousAmountInUnits,
           dpcl.AmountInUnits,
           dpcl.PreviousLotCountDecimal,
           dpcl.LotCountDecimal           AS NewLotCountDecimal,
           ROW_NUMBER() OVER (
               PARTITION BY dpcl.PositionID, dpcl.ChangeTypeID
               ORDER BY dpcl.Occurred
           ) AS RN
    FROM dwh_daily_process.migration_tables.Dim_PositionChangeLog dpcl
    WHERE dpcl.OccurredDateID <= V_dtID
      AND dpcl.ChangeTypeID IN (0, 1, 11, 12)
      AND dpcl.PositionID IN (SELECT PositionID FROM v_all_pos);

    -- ------------------------------------------------------------------
    -- (6) Initial metrics at OPEN time (one row per position).
    -- ------------------------------------------------------------------
    CREATE OR REPLACE TEMPORARY VIEW v_origin_metrics_raw AS
    SELECT DISTINCT
           cl.PositionID,
           cl.NewLotCountDecimal                         AS InitialLotCountDecimal,
           cl.NewAmount                                  AS InitialInvestedAmount,
           dis.ProviderMarginPerLot                      AS InitialProviderMarginPerLot,
           dis.eToroMarginPerLot                         AS InitialeToroMarginPerLot,
           cl.NewLotCountDecimal * dis.ProviderMarginPerLot AS InitialProviderMargin,
           cl.NewLotCountDecimal * dis.eToroMarginPerLot    AS InitialeToroMargin
    FROM v_all_pos p
    JOIN v_changelog cl
      ON p.PositionID = cl.PositionID
     AND cl.ChangeTypeID = 0
    JOIN dwh_daily_process.migration_tables.Dim_Position dp
      ON cl.PositionID = dp.PositionID
    LEFT JOIN dwh_daily_process.migration_tables.Dim_Instrument_Snapshot dis
      ON dp.InstrumentID = dis.InstrumentID
     AND CAST(dp.OpenOccurred  AS DATE) = CAST(dis.SettlementTime AS DATE)
     AND dis.IsFuture = 1;

    -- ------------------------------------------------------------------
    -- (7) First partial-close event per position (Occurred ascending RN=1).
    -- ------------------------------------------------------------------
    CREATE OR REPLACE TEMPORARY VIEW v_first_partial AS
    SELECT c.PositionID,
           c.Occurred,
           c.OccurredDateID,
           c.PreviousLotCountDecimal AS InitialLotCountDecimal
    FROM v_changelog c
    WHERE c.ChangeTypeID = 12
      AND c.RN = 1;

    -- ------------------------------------------------------------------
    -- (8) Step 3 in the original: overlay origin metrics with the
    -- pre-partial lot count when a partial-close exists.
    -- ------------------------------------------------------------------
    CREATE OR REPLACE TEMPORARY VIEW v_origin_metrics AS
    SELECT m.PositionID,
           COALESCE(fp.InitialLotCountDecimal, m.InitialLotCountDecimal) AS InitialLotCountDecimal,
           m.InitialInvestedAmount,
           m.InitialProviderMarginPerLot,
           m.InitialeToroMarginPerLot,
           m.InitialProviderMargin,
           m.InitialeToroMargin
    FROM v_origin_metrics_raw m
    LEFT JOIN v_first_partial fp
      ON m.PositionID = fp.PositionID;

    -- ------------------------------------------------------------------
    -- (9) Latest partial-close (ChangeTypeID=12) BEFORE SettlementTime
    -- per open position. Replaces original LATERAL JOIN t2.
    -- ------------------------------------------------------------------
    CREATE OR REPLACE TEMPORARY VIEW v_last_12_open AS
    SELECT PositionID, NewLotCountDecimal
    FROM (
        SELECT cl.PositionID,
               cl.NewLotCountDecimal,
               ROW_NUMBER() OVER (
                   PARTITION BY cl.PositionID
                   ORDER BY cl.Occurred DESC
               ) AS rn
        FROM v_changelog cl
        JOIN v_open_base oas
          ON cl.PositionID = oas.PositionID
        WHERE cl.ChangeTypeID = 12
          AND cl.Occurred <= oas.SettlementTime
    ) ranked
    WHERE rn = 1;

    -- ------------------------------------------------------------------
    -- (10) Latest amount-change (ChangeTypeID=1) BEFORE SettlementTime
    -- per open position. Replaces original LATERAL JOIN t4.
    -- ------------------------------------------------------------------
    CREATE OR REPLACE TEMPORARY VIEW v_last_1_open AS
    SELECT PositionID, NewAmount
    FROM (
        SELECT cl.PositionID,
               cl.NewAmount,
               ROW_NUMBER() OVER (
                   PARTITION BY cl.PositionID
                   ORDER BY cl.Occurred DESC
               ) AS rn
        FROM v_changelog cl
        JOIN v_open_base oas
          ON cl.PositionID = oas.PositionID
        WHERE cl.ChangeTypeID = 1
          AND cl.Occurred <= oas.SettlementTime
    ) ranked
    WHERE rn = 1;

    -- ------------------------------------------------------------------
    -- (11) The ChangeTypeID=0 (open) row per position -- final fallback
    -- for LotCount / InvestedAmount. Replaces original `t5`.
    -- ------------------------------------------------------------------
    CREATE OR REPLACE TEMPORARY VIEW v_open_t5 AS
    SELECT PositionID, NewLotCountDecimal, NewAmount
    FROM v_changelog
    WHERE ChangeTypeID = 0
      AND RN = 1;

    -- ------------------------------------------------------------------
    -- (12) Latest partial-close-child (ChangeTypeID=11) BEFORE
    -- CloseOccurred per closed position.
    -- ------------------------------------------------------------------
    CREATE OR REPLACE TEMPORARY VIEW v_last_11_closed AS
    SELECT PositionID, NewLotCountDecimal
    FROM (
        SELECT cl.PositionID,
               cl.NewLotCountDecimal,
               ROW_NUMBER() OVER (
                   PARTITION BY cl.PositionID
                   ORDER BY cl.Occurred DESC
               ) AS rn
        FROM v_changelog cl
        JOIN v_closed_base cls
          ON cl.PositionID = cls.PositionID
        WHERE cl.ChangeTypeID = 11
          AND cl.Occurred <= cls.CloseOccurred
    ) ranked
    WHERE rn = 1;

    -- ------------------------------------------------------------------
    -- (13) Apply the open-side updates as a view:
    --   LotCountDecimal = COALESCE(base, last_12, t5)
    --   InvestedAmount  = COALESCE(base, last_1,  t5)
    --   IsPartialCloseParent = 1 iff first_partial exists for the position
    --   PnL = LotCount * Multiplier * (SettlementPrice - InitForexRate)
    --   plus NULL-cleanup for child / OriginalPositionID.
    -- ------------------------------------------------------------------
    CREATE OR REPLACE TEMPORARY VIEW v_open_final AS
    SELECT b.RunDate,
           b.DateID,
           b.SettlementCategory,
           b.CID,
           b.PositionID,
           CASE WHEN COALESCE(b.IsPartialCloseChild, 0) = 0
                THEN b.PositionID
                ELSE b.OriginalPositionID
           END                                            AS OriginalPositionID,
           b.InstrumentID,
           COALESCE(b.LotCountDecimal,
                    l12.NewLotCountDecimal,
                    t5.NewLotCountDecimal)               AS LotCountDecimal,
           b.SettlementTime,
           b.SettlementPrice,
           COALESCE(b.InvestedAmount,
                    l1.NewAmount,
                    t5.NewAmount)                        AS InvestedAmount,
           b.OpenOccurred,
           b.CloseOccurred,
           b.InitForexRate,
           b.EndForexRate,
           CASE WHEN fp.PositionID IS NOT NULL THEN 1 ELSE 0 END AS IsPartialCloseParent,
           COALESCE(b.IsPartialCloseChild, 0)            AS IsPartialCloseChild,
           b.IsBuy,
           b.ProviderID,
           b.Multiplier,
           b.ProviderMargin,
           b.eToroMargin,
           (COALESCE(b.LotCountDecimal,
                     l12.NewLotCountDecimal,
                     t5.NewLotCountDecimal) * b.Multiplier * b.SettlementPrice)
           - (COALESCE(b.LotCountDecimal,
                       l12.NewLotCountDecimal,
                       t5.NewLotCountDecimal) * b.Multiplier * b.InitForexRate) AS PnL
    FROM v_open_base b
    LEFT JOIN v_last_12_open  l12 ON b.PositionID = l12.PositionID
    LEFT JOIN v_last_1_open   l1  ON b.PositionID = l1.PositionID
    LEFT JOIN v_open_t5       t5  ON b.PositionID = t5.PositionID
    LEFT JOIN v_first_partial fp  ON b.PositionID = fp.PositionID;

    -- ------------------------------------------------------------------
    -- (14) Apply the closed-side updates:
    --   LotCountDecimal = base, or last partial-child if it exists.
    --   plus NULL-cleanup for parent/child + OriginalPositionID.
    -- ------------------------------------------------------------------
    CREATE OR REPLACE TEMPORARY VIEW v_closed_final AS
    SELECT b.RunDate,
           b.DateID,
           b.SettlementCategory,
           b.CID,
           b.PositionID,
           CASE WHEN COALESCE(b.IsPartialCloseChild, 0) = 0
                THEN b.PositionID
                ELSE b.OriginalPositionID
           END                                            AS OriginalPositionID,
           b.InstrumentID,
           CASE WHEN l11.PositionID IS NULL
                THEN b.LotCountDecimal
                ELSE l11.NewLotCountDecimal
           END                                            AS LotCountDecimal,
           b.SettlementTime,
           b.SettlementPrice,
           b.InvestedAmount,
           b.OpenOccurred,
           b.CloseOccurred,
           b.InitForexRate,
           b.EndForexRate,
           COALESCE(b.IsPartialCloseParent, 0)            AS IsPartialCloseParent,
           COALESCE(b.IsPartialCloseChild, 0)             AS IsPartialCloseChild,
           b.IsBuy,
           b.ProviderID,
           b.Multiplier,
           b.ProviderMargin,
           b.eToroMargin,
           b.PnL
    FROM v_closed_base b
    LEFT JOIN v_last_11_closed l11 ON b.PositionID = l11.PositionID;

    -- ------------------------------------------------------------------
    -- (15) Wide final row for opens -- add the Initial* metrics from
    -- v_origin_metrics + the instrument snapshot.
    -- ------------------------------------------------------------------
    CREATE OR REPLACE TEMPORARY VIEW v_prep_opens AS
    SELECT oas.RunDate                                     AS `TIMESTAMP`,
           oas.DateID,
           oas.SettlementCategory,
           oas.CID,
           oas.PositionID,
           oas.OriginalPositionID,
           oas.InstrumentID,
           oas.LotCountDecimal,
           oas.SettlementTime,
           oas.SettlementPrice,
           oas.InvestedAmount,
           oas.OpenOccurred,
           oas.CloseOccurred,
           oas.InitForexRate,
           oas.EndForexRate,
           oas.IsPartialCloseParent,
           oas.IsPartialCloseChild,
           oas.IsBuy,
           oas.ProviderID,
           oas.Multiplier,
           oas.LotCountDecimal * dis.ProviderMarginPerLot  AS ProviderMargin,
           oas.LotCountDecimal * dis.eToroMarginPerLot     AS eToroMargin,
           oas.PnL,
           m.InitialLotCountDecimal                                              AS InitialLotCountDecimalFull,
           m.InitialInvestedAmount                                               AS InitialInvestedAmountFull,
           m.InitialProviderMarginPerLot * m.InitialLotCountDecimal              AS InitialProviderMarginFull,
           m.InitialeToroMarginPerLot    * m.InitialLotCountDecimal              AS InitialeToroMarginFull,
           oas.LotCountDecimal                                                   AS InitialLotCountDecimalResidual,
           m.InitialInvestedAmount * oas.LotCountDecimal / NULLIF(m.InitialLotCountDecimal, 0)
                                                                                 AS InitialInvestedAmountResidual,
           m.InitialProviderMarginPerLot * oas.LotCountDecimal                   AS InitialProviderMarginResidual,
           m.InitialeToroMarginPerLot    * oas.LotCountDecimal                   AS InitialeToroMarginResidual,
           current_timestamp()                                                   AS UpdateDate
    FROM v_open_final oas
    LEFT JOIN dwh_daily_process.migration_tables.Dim_Instrument_Snapshot dis
      ON oas.InstrumentID   = dis.InstrumentID
     AND oas.SettlementTime = dis.SettlementTime
    LEFT JOIN v_origin_metrics m
      ON oas.PositionID = m.PositionID;

    -- ------------------------------------------------------------------
    -- (16) Wide final row for closed -- same shape as opens.
    -- ------------------------------------------------------------------
    CREATE OR REPLACE TEMPORARY VIEW v_prep_closed AS
    SELECT oas.RunDate                                     AS `TIMESTAMP`,
           oas.DateID,
           oas.SettlementCategory,
           oas.CID,
           oas.PositionID,
           oas.OriginalPositionID,
           oas.InstrumentID,
           oas.LotCountDecimal,
           oas.SettlementTime,
           oas.SettlementPrice,
           oas.InvestedAmount,
           oas.OpenOccurred,
           oas.CloseOccurred,
           oas.InitForexRate,
           oas.EndForexRate,
           oas.IsPartialCloseParent,
           oas.IsPartialCloseChild,
           oas.IsBuy,
           oas.ProviderID,
           oas.Multiplier,
           oas.LotCountDecimal * dis.ProviderMarginPerLot  AS ProviderMargin,
           oas.LotCountDecimal * dis.eToroMarginPerLot     AS eToroMargin,
           oas.PnL,
           m.InitialLotCountDecimal                                              AS InitialLotCountDecimalFull,
           m.InitialInvestedAmount                                               AS InitialInvestedAmountFull,
           m.InitialProviderMarginPerLot * m.InitialLotCountDecimal              AS InitialProviderMarginFull,
           m.InitialeToroMarginPerLot    * m.InitialLotCountDecimal              AS InitialeToroMarginFull,
           oas.LotCountDecimal                                                   AS InitialLotCountDecimalResidual,
           m.InitialInvestedAmount * oas.LotCountDecimal / NULLIF(m.InitialLotCountDecimal, 0)
                                                                                 AS InitialInvestedAmountResidual,
           m.InitialProviderMarginPerLot * oas.LotCountDecimal                   AS InitialProviderMarginResidual,
           m.InitialeToroMarginPerLot    * oas.LotCountDecimal                   AS InitialeToroMarginResidual,
           current_timestamp()                                                   AS UpdateDate
    FROM v_closed_final oas
    LEFT JOIN dwh_daily_process.migration_tables.Dim_Instrument_Snapshot dis
      ON oas.InstrumentID = dis.InstrumentID
     AND oas.DateID       = dis.DateID
    LEFT JOIN v_origin_metrics m
      ON oas.OriginalPositionID = m.PositionID;

    -- ------------------------------------------------------------------
    -- (17) Idempotent reload for V_dtID.
    -- ------------------------------------------------------------------
    DELETE FROM dwh_daily_process.migration_tables.Fact_Position_Futures_Snapshot
    WHERE DateID = V_dtID;

    INSERT INTO dwh_daily_process.migration_tables.Fact_Position_Futures_Snapshot
        (`TIMESTAMP`, DateID, SettlementCategory, CID, PositionID,
         OriginalPositionID, InstrumentID, LotCountDecimal, SettlementTime,
         SettlementPrice, InvestedAmount, OpenOccurred, CloseOccurred,
         InitForexRate, EndForexRate, IsPartialCloseParent, IsPartialCloseChild,
         IsBuy, ProviderID, Multiplier, ProviderMargin, eToroMargin, PnL,
         InitialLotCountDecimalFull, InitialInvestedAmountFull,
         InitialProviderMarginFull, InitialeToroMarginFull,
         InitialLotCountDecimalResidual, InitialInvestedAmountResidual,
         InitialProviderMarginResidual, InitialeToroMarginResidual,
         UpdateDate)
    SELECT * FROM v_prep_opens
    UNION ALL
    SELECT * FROM v_prep_closed;

    -- ------------------------------------------------------------------
    -- Cleanup: drop the session-scoped views so nothing leaks.
    -- ------------------------------------------------------------------
    DROP VIEW IF EXISTS v_last_prices;
    DROP VIEW IF EXISTS v_open_base;
    DROP VIEW IF EXISTS v_closed_base;
    DROP VIEW IF EXISTS v_all_pos;
    DROP VIEW IF EXISTS v_changelog;
    DROP VIEW IF EXISTS v_origin_metrics_raw;
    DROP VIEW IF EXISTS v_first_partial;
    DROP VIEW IF EXISTS v_origin_metrics;
    DROP VIEW IF EXISTS v_last_12_open;
    DROP VIEW IF EXISTS v_last_1_open;
    DROP VIEW IF EXISTS v_open_t5;
    DROP VIEW IF EXISTS v_last_11_closed;
    DROP VIEW IF EXISTS v_open_final;
    DROP VIEW IF EXISTS v_closed_final;
    DROP VIEW IF EXISTS v_prep_opens;
    DROP VIEW IF EXISTS v_prep_closed;
END;
