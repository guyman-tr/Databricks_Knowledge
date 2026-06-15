-- =================================================================================================
-- FIX: main.etoro_kpi_prep.tvf_ddr_fact_aum  (DDR Fact_AUM Options bug + phantom DateID)
-- =================================================================================================
-- Root cause (see proposals/bad_ftd_cohort_2026_05/ROOT_CAUSE_DDR_DIVERGENCE_2026-06-14.md):
--   1. The `opts` FULL OUTER JOIN included `COALESCE(cb.DateID, iban.DateID) = opts.DateID`.
--      Options snapshot lags 1 day (max DateID in v_options_aum = p_dateID - 1), so this predicate
--      is ALWAYS false for TP-having CIDs → Options side becomes NULL → OptionsTotalEquity = 0.
--   2. The output used `COALESCE(cb.DateID, iban.DateID, opts.DateID) AS DateID`. For Options-only
--      CIDs (no cb/iban presence) this produced rows with `DateID = yesterday`, ending up in
--      yesterday's partition where DELETE-WHERE-DateID-=-p_dateID never touches them
--      (the "ghost rows" — 8,030 CIDs / $8.7M observed on 20260611, 8,050 CIDs / $13.5M on 20260612).
--      It can also produce NULL DateID rows if all three source rows have NULL DateID.
--
-- Fix:
--   A. Force `p_dateID AS DateID` in the final SELECT — eliminates phantom DateIDs (incl. NULL).
--   B. Drop the DateID equality from the opts FULL OUTER JOIN — restores Options attachment to TP rows.
--
-- Synapse parity:
--   Synapse SP_DDR_Fact_AUM joins Options on CID only (`ON COALESCE(cb.CID, i.CID) = ob.RealCID`)
--   and hardcodes the output DateID to `@dateID`. This patch makes DBX match.
-- =================================================================================================

CREATE OR REPLACE FUNCTION main.etoro_kpi_prep.tvf_ddr_fact_aum(p_dateID INT)
RETURNS TABLE (
  dp_uuid                    STRING,
  source_platform            STRING,
  gcid                       INT,
  RealCID                    BIGINT,
  DateID                     INT,
  RealizedEquityTP           DECIMAL(28,6),
  TotalLiabilityTP           DECIMAL(28,6),
  InProcessCashout           DECIMAL(28,6),
  NOP                        DECIMAL(28,6),
  NOPCrypto                  DECIMAL(28,6),
  NOPCryptoCFD               DECIMAL(28,6),
  NOPStocks                  DECIMAL(28,6),
  NOPStocksCFD               DECIMAL(28,6),
  TotalRealCryptoLoan        DECIMAL(28,6),
  TotalPositionPNL           DECIMAL(28,6),
  TotalInvestedAmount        DECIMAL(28,6),
  TotalEquityTP              DECIMAL(29,6),
  Bonus                      DECIMAL(28,6),
  CashInCopy                 DECIMAL(19,4),
  CopyInvestedAmount         DECIMAL(19,4),
  CopyStockOrders            DECIMAL(19,4),
  CopyPositionPnL            DECIMAL(16,2),
  EquityCopy                 DECIMAL(22,4),
  InvestedAmountCopy         DECIMAL(21,4),
  StockInvestedAmount        DECIMAL(19,4),
  StockOrders                DECIMAL(19,4),
  StocksPositionPnL          DECIMAL(16,2),
  MirrorStockInvestedAmount  DECIMAL(19,4),
  MirrorStocksPositionPnL    DECIMAL(16,2),
  EquityStocksManual         DECIMAL(23,4),
  InvestedAmountStocksManual DECIMAL(21,4),
  InvestedAmountCryptoManual DECIMAL(19,4),
  CryptoManualPositionPnL    DECIMAL(16,2),
  EquityCryptoManual         DECIMAL(20,4),
  TotalRealCrypto            DECIMAL(16,2),
  TotalRealStocks            DECIMAL(16,2),
  CreditTP                   DECIMAL(19,4),
  ActualNWA                  DECIMAL(20,4),
  IBANBalance                DECIMAL(38,12),
  OptionsTotalEquity         DECIMAL(18,2),
  OptionsCashEquity          DECIMAL(18,2),
  RealizedEquityGlobal       DECIMAL(38,11),
  TotalLiabilityGlobal       DECIMAL(38,10),
  EquityGlobal               DECIMAL(38,10),
  CreditGlobal               DECIMAL(38,10),
  EquityAllPlatforms         DECIMAL(38,10)
)
READS SQL DATA
RETURN
WITH vl AS (
  SELECT
    DateID,
    CID,
    COALESCE(TotalMirrorCash, 0) AS CashInCopy,
    COALESCE(TotalMirrorPositionsAmount, 0) AS CopyInvestedAmount,
    COALESCE(TotalMirrorStockOrders, 0) AS CopyStockOrders,
    COALESCE(CopyPositionPnL, 0) AS CopyPositionPnL,
    COALESCE(TotalMirrorCash, 0)
      + COALESCE(TotalMirrorPositionsAmount, 0)
      + COALESCE(TotalMirrorStockOrders, 0)
      + COALESCE(CopyPositionPnL, 0) AS EquityCopy,
    COALESCE(TotalMirrorPositionsAmount, 0)
      + COALESCE(TotalMirrorStockOrders, 0)
      + COALESCE(CopyPositionPnL, 0) AS InvestedAmountCopy,
    COALESCE(TotalStockPositionAmount, 0) AS StockInvestedAmount,
    COALESCE(TotalStockOrders, 0) AS StockOrders,
    COALESCE(StocksPositionPnL, 0) AS StocksPositionPnL,
    COALESCE(TotalMirrorStockPositionAmount, 0) AS MirrorStockInvestedAmount,
    COALESCE(MirrorStocksPositionPnL, 0) AS MirrorStocksPositionPnL,
    COALESCE(TotalStockPositionAmount, 0)
      + COALESCE(TotalStockOrders, 0)
      + COALESCE(StocksPositionPnL, 0)
      - COALESCE(TotalMirrorStockPositionAmount, 0)
      - COALESCE(MirrorStocksPositionPnL, 0) AS EquityStocksManual,
    COALESCE(TotalStockPositionAmount, 0)
      + COALESCE(TotalStockOrders, 0)
      - COALESCE(TotalMirrorStockPositionAmount, 0) AS InvestedAmountStocksManual,
    COALESCE(TotalCryptoManualPosition, 0) AS InvestedAmountCryptoManual,
    COALESCE(ManualCryptoPositionPnL, 0) AS CryptoManualPositionPnL,
    COALESCE(TotalCryptoManualPosition, 0)
      + COALESCE(ManualCryptoPositionPnL, 0) AS EquityCryptoManual,
    COALESCE(TotalRealCrypto, 0) AS TotalRealCrypto,
    COALESCE(TotalRealStocks, 0) AS TotalRealStocks,
    COALESCE(Credit, 0) AS Credit,
    COALESCE(ActualNWA, 0) AS ActualNWA
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities
  WHERE DateID = p_dateID
),
cb AS (
  SELECT
    DateID,
    CID,
    SUM(COALESCE(Bonus, 0)) AS Bonus,
    SUM(COALESCE(realizedEquity, 0)) AS realizedEquity,
    SUM(COALESCE(TotalLiability, 0)) AS TotalLiability,
    SUM(COALESCE(InProcessCashout, 0)) AS InProcessCashout,
    SUM(COALESCE(NOP, 0)) AS NOP,
    SUM(COALESCE(NOPCrypto, 0)) AS NOPCrypto,
    SUM(COALESCE(NOPCryptoCFD, 0)) AS NOPCryptoCFD,
    SUM(COALESCE(NOPStocks, 0)) AS NOPStocks,
    SUM(COALESCE(NOPStocksCFD, 0)) AS NOPStocksCFD,
    SUM(COALESCE(TotalRealCryptoLoan, 0)) AS TotalRealCryptoLoan,
    SUM(COALESCE(PositionPNL, 0)) AS PositionPNL,
    SUM(COALESCE(PositionAmount, 0)) AS PositionAmount,
    SUM(COALESCE(TotalLiability, 0) + COALESCE(actualNWA, 0)) AS TotalEquity
  FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_cid_level_new
  WHERE DateID = p_dateID
  GROUP BY DateID, CID
),
iban AS (
  SELECT
    BalanceDateID AS DateID,
    CID,
    SUM(ClosingBalanceBO * USDApproxRate) AS USDBalance
  FROM main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance
  WHERE BalanceDateID = p_dateID
    AND GCID IS NOT NULL
    AND GCID <> 0
  GROUP BY BalanceDateID, CID
),
opts_max_date AS (
  SELECT MAX(DateID) AS max_opts_dateID
  FROM main.etoro_kpi_prep.v_options_aum
  WHERE DateID <= p_dateID
),
opts AS (
  SELECT
    o.DateID,
    xw.cid AS CID,
    o.OptionsTotalEquity,
    o.OptionsCashEquity
  FROM main.etoro_kpi_prep.v_options_aum o
    JOIN opts_max_date omd
      ON o.DateID = omd.max_opts_dateID
    JOIN main.etoro_kpi_prep.v_dim_dataplatform_uuid xw
      ON o.GCID = xw.gcid
),
equity_prep AS (
  SELECT
    -- ░░░ FIX A: hardcode p_dateID instead of COALESCE — prevents phantom NULL or yesterday-DateID rows ░░░
    p_dateID AS DateID,
    COALESCE(cb.CID, iban.CID, opts.CID) AS CID,
    COALESCE(cb.realizedEquity, 0) AS RealizedEquityTP,
    COALESCE(cb.TotalLiability, 0) AS TotalLiabilityTP,
    COALESCE(cb.InProcessCashout, 0) AS InProcessCashout,
    COALESCE(cb.NOP, 0) AS NOP,
    COALESCE(cb.NOPCrypto, 0) AS NOPCrypto,
    COALESCE(cb.NOPCryptoCFD, 0) AS NOPCryptoCFD,
    COALESCE(cb.NOPStocks, 0) AS NOPStocks,
    COALESCE(cb.NOPStocksCFD, 0) AS NOPStocksCFD,
    COALESCE(cb.TotalRealCryptoLoan, 0) AS TotalRealCryptoLoan,
    COALESCE(cb.PositionPNL, 0) AS TotalPositionPNL,
    COALESCE(cb.PositionAmount, 0) AS TotalInvestedAmount,
    COALESCE(cb.TotalEquity, 0) AS TotalEquityTP,
    COALESCE(cb.Bonus, 0) AS Bonus,
    COALESCE(vl.CashInCopy, 0) AS CashInCopy,
    COALESCE(vl.CopyInvestedAmount, 0) AS CopyInvestedAmount,
    COALESCE(vl.CopyStockOrders, 0) AS CopyStockOrders,
    COALESCE(vl.CopyPositionPnL, 0) AS CopyPositionPnL,
    COALESCE(vl.EquityCopy, 0) AS EquityCopy,
    COALESCE(vl.InvestedAmountCopy, 0) AS InvestedAmountCopy,
    COALESCE(vl.StockInvestedAmount, 0) AS StockInvestedAmount,
    COALESCE(vl.StockOrders, 0) AS StockOrders,
    COALESCE(vl.StocksPositionPnL, 0) AS StocksPositionPnL,
    COALESCE(vl.MirrorStockInvestedAmount, 0) AS MirrorStockInvestedAmount,
    COALESCE(vl.MirrorStocksPositionPnL, 0) AS MirrorStocksPositionPnL,
    COALESCE(vl.EquityStocksManual, 0) AS EquityStocksManual,
    COALESCE(vl.InvestedAmountStocksManual, 0) AS InvestedAmountStocksManual,
    COALESCE(vl.InvestedAmountCryptoManual, 0) AS InvestedAmountCryptoManual,
    COALESCE(vl.CryptoManualPositionPnL, 0) AS CryptoManualPositionPnL,
    COALESCE(vl.EquityCryptoManual, 0) AS EquityCryptoManual,
    COALESCE(vl.TotalRealCrypto, 0) AS TotalRealCrypto,
    COALESCE(vl.TotalRealStocks, 0) AS TotalRealStocks,
    COALESCE(vl.Credit, 0) AS CreditTP,
    COALESCE(vl.ActualNWA, 0) AS ActualNWA,
    COALESCE(iban.USDBalance, 0) AS IBANBalance,
    COALESCE(opts.OptionsTotalEquity, 0) AS OptionsTotalEquity,
    COALESCE(opts.OptionsCashEquity, 0) AS OptionsCashEquity
  FROM cb
    LEFT JOIN vl
      ON cb.CID = vl.CID
      AND cb.DateID = vl.DateID
    FULL OUTER JOIN iban
      ON cb.CID = iban.CID
      AND cb.DateID = iban.DateID
    -- ░░░ FIX B: drop the DateID predicate so Options (which lags 1 day) actually joins ░░░
    FULL OUTER JOIN opts
      ON COALESCE(cb.CID, iban.CID) = opts.CID
)
SELECT
  xw.dp_uuid,
  xw.source_platform,
  xw.gcid,
  ep.CID AS RealCID,
  ep.DateID,
  ep.RealizedEquityTP,
  ep.TotalLiabilityTP,
  ep.InProcessCashout,
  ep.NOP,
  ep.NOPCrypto,
  ep.NOPCryptoCFD,
  ep.NOPStocks,
  ep.NOPStocksCFD,
  ep.TotalRealCryptoLoan,
  ep.TotalPositionPNL,
  ep.TotalInvestedAmount,
  ep.TotalEquityTP,
  ep.Bonus,
  ep.CashInCopy,
  ep.CopyInvestedAmount,
  ep.CopyStockOrders,
  ep.CopyPositionPnL,
  ep.EquityCopy,
  ep.InvestedAmountCopy,
  ep.StockInvestedAmount,
  ep.StockOrders,
  ep.StocksPositionPnL,
  ep.MirrorStockInvestedAmount,
  ep.MirrorStocksPositionPnL,
  ep.EquityStocksManual,
  ep.InvestedAmountStocksManual,
  ep.InvestedAmountCryptoManual,
  ep.CryptoManualPositionPnL,
  ep.EquityCryptoManual,
  ep.TotalRealCrypto,
  ep.TotalRealStocks,
  ep.CreditTP,
  ep.ActualNWA,
  ep.IBANBalance,
  ep.OptionsTotalEquity,
  ep.OptionsCashEquity,
  ep.RealizedEquityTP + ep.IBANBalance AS RealizedEquityGlobal,
  ep.TotalLiabilityTP + ep.IBANBalance + ep.OptionsTotalEquity AS TotalLiabilityGlobal,
  ep.TotalEquityTP + ep.IBANBalance + ep.OptionsTotalEquity AS EquityGlobal,
  ep.CreditTP + ep.IBANBalance + ep.OptionsCashEquity AS CreditGlobal,
  ep.TotalEquityTP + ep.IBANBalance + ep.OptionsTotalEquity AS EquityAllPlatforms
FROM equity_prep ep
  LEFT JOIN (
    SELECT cid, dp_uuid, source_platform, gcid
    FROM main.etoro_kpi_prep.v_dim_dataplatform_uuid
    QUALIFY ROW_NUMBER() OVER (PARTITION BY cid ORDER BY dp_uuid) = 1
  ) xw
    ON ep.CID = xw.cid
WHERE
  (ep.TotalEquityTP + ep.IBANBalance + ep.OptionsTotalEquity) <> 0
  OR (
    ep.TotalLiabilityTP = 0
    AND (
      ep.NOP <> 0
      OR ep.TotalPositionPNL <> 0
      OR ep.RealizedEquityTP <> 0
      OR ep.InProcessCashout <> 0
      OR ep.TotalInvestedAmount <> 0
      OR ep.ActualNWA <> 0
    )
  );

-- =================================================================================================
-- POST-DEPLOY CLEANUP — run manually after deploying the TVF fix above.
-- This wipes the historical ghost rows that the broken TVF accumulated.
-- =================================================================================================

-- (1) Phantom NULL DateID rows (if any):
DELETE FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum
WHERE DateID IS NULL;

-- (2) OPTIONAL: phantom dated rows (rows in past partitions that the SP wrote on a LATER run).
--     These show up as "Options-only" rows in past partitions with TP fields = 0 and only
--     OptionsTotalEquity / OptionsCashEquity populated. Identify before deleting:
--
-- SELECT DateID, COUNT(*) AS phantom_rows
-- FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum
-- WHERE RealizedEquityTP = 0 AND TotalLiabilityTP = 0 AND TotalEquityTP = 0
--   AND TotalInvestedAmount = 0 AND TotalPositionPNL = 0 AND ActualNWA = 0
--   AND IBANBalance = 0
--   AND (OptionsTotalEquity <> 0 OR OptionsCashEquity <> 0)
-- GROUP BY DateID ORDER BY DateID DESC;
--
-- If the above looks clean, you can re-run each affected DateID through the (now-fixed) SP
-- and it will overwrite the ghosts cleanly (DELETE WHERE DateID = p_dateID, then INSERT).
