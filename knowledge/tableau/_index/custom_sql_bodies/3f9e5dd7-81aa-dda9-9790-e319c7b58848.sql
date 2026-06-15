-- =============================================================================
-- Crypto Buys & Sells by State / Regulation (USA, excl. CoinDeem)
-- Window: trailing 2 years from current month, dynamic on each run
-- =============================================================================

WITH
-- --- Dynamic date threshold, computed once at planning time -------------------
-- Equivalent to: first day of (current_month - 24 months), in YYYYMMDD int form.
-- Folded to a constant by Spark so partition pruning + data skipping work
-- against integer Date columns (OpenDateID, CloseDateID, ToDateID, FromDateID).
date_threshold AS (
  SELECT CAST(DATE_FORMAT(DATE_TRUNC('month', current_date() - INTERVAL '2' YEAR),
                          'yyyyMMdd') AS INT) AS yyyymmdd_int
),

-- --- US customers active within the review window ----------------------------
-- IMPORTANT: this CTE shrinks the dim_position scan via a broadcast probe.
-- If the transaction-date filters below are widened, widen this filter too —
-- otherwise older transactions will be silently dropped at the dim_position join.
eligible_cids AS (
  SELECT DISTINCT m.RealCID
  FROM bi_output_stg.bi_output_compliance_map_usa_cid_state_regulation_daily m
  CROSS JOIN date_threshold dt
  WHERE m.ToDateID >= dt.yyyymmdd_int
),

-- --- Crypto positions: opens (Buy) + closes (Sell) ---------------------------
-- Filtering on OpenDateID / CloseDateID (real transaction timestamps as ints),
crypto_tx AS (
  SELECT
    'Buy'                              AS ActionType,
    dp.OpenDateID                      AS DateID,
    CAST(dp.OpenOccurred AS DATE)      AS TxDate,
    dp.CID,
    di.Name                            AS CryptoInstrument,
    dp.PositionID,
    dp.InitialAmountCents / 100.0      AS Amount
  FROM main.dwh.dim_position dp
  JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument di
    ON dp.InstrumentID = di.InstrumentID
   AND di.InstrumentTypeID = 10                       -- crypto instruments only
  JOIN eligible_cids ec
    ON ec.RealCID = dp.CID
  CROSS JOIN date_threshold dt
  WHERE dp.RegulationIDOnOpen IN (7, 8)               -- US crypto regulations
    AND COALESCE(dp.IsPartialCloseChild, 0) = 0       -- exclude phantom child positions
    AND COALESCE(dp.IsAirDrop, 0)         <> 1        -- exclude airdrops
    AND dp.OpenDateID >= dt.yyyymmdd_int

  UNION ALL

  SELECT
    'Sell'                             AS ActionType,
    dp.CloseDateID                     AS DateID,
    CAST(dp.CloseOccurred AS DATE)     AS TxDate,
    dp.CID,
    di.Name                            AS CryptoInstrument,
    dp.PositionID,
    dp.Amount + dp.NetProfit           AS Amount
  FROM main.dwh.dim_position dp
  JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument di
    ON dp.InstrumentID = di.InstrumentID
   AND di.InstrumentTypeID = 10
  JOIN eligible_cids ec
    ON ec.RealCID = dp.CID
  CROSS JOIN date_threshold dt
  WHERE dp.RegulationIDOnOpen IN (7, 8)
    AND COALESCE(dp.IsAirDrop, 0) <> 1
    AND (dp.RedeemID IS NULL OR dp.RedeemStatus <> 6) -- exclude successful redeems
    AND dp.CloseDateID >= dt.yyyymmdd_int
),

-- --- Pre-aggregate at (CID, day, instrument, action) level -------------------
-- Done before the map join to keep the cardinality going into the join small.
tx_daily AS (
  SELECT
    ActionType,
    DateID,
    TxDate,
    LAST_DAY(TxDate)            AS MonthEndDate,
    CID,
    CryptoInstrument,
    COUNT(DISTINCT PositionID)  AS TransactionCount,
    SUM(Amount)                 AS AmountUSD
  FROM crypto_tx
  GROUP BY ActionType, DateID, TxDate, LAST_DAY(TxDate), CID, CryptoInstrument
)

-- --- Final output: attribute each transaction to the state/regulation in effect on that day
SELECT
  t.MonthEndDate,
  r.Name              AS Regulation,
  s.StateName,
  s.StateShortName,
  t.ActionType,
  t.CryptoInstrument,
  SUM(t.TransactionCount)  AS TransactionCount,
  SUM(t.AmountUSD)         AS AmountUSD
FROM tx_daily t
JOIN bi_output_stg.bi_output_compliance_map_usa_cid_state_regulation_daily s
  ON  t.CID    = s.RealCID
  AND t.DateID BETWEEN s.FromDateID AND s.ToDateID
LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation r
  ON s.RegulationID = r.ID
GROUP BY
  t.MonthEndDate,
  r.Name,
  s.StateName,
  s.StateShortName,
  t.ActionType,
  t.CryptoInstrument
/*ORDER BY
  t.MonthEndDate DESC,
  Regulation,
  s.StateShortName,
  t.ActionType,
  t.CryptoInstrument;
  */