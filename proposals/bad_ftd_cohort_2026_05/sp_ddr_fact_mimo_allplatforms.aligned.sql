-- =====================================================================
-- sp_ddr_fact_mimo_allplatforms (aligned — thin materializer)
-- ---------------------------------------------------------------------
-- All MIMO logic (FTD recovery, bad-cohort filter, cross-platform
-- unification) lives in main.etoro_kpi_prep.v_mimo_allplatforms.
-- This SP just materializes the view to the fact table.
--
-- THREE PHASES (mirror the structural shape of the Synapse SP)
--   1. Per-DateID load for TradingPlatform + eMoney (these are
--      reliably daily — incremental refresh).
--   2. Full refresh for Options (Synapse parity: "best effort, not
--      reliably ready at DDR send time" → wipe all dates, full reload).
--   3. Full refresh for MoneyFarm (same model — best effort, FTD-only).
--
-- BACK-DATING WORKFLOW
--   To pick up DimCustomer updates that affect a historical date,
--   rerun this SP for that DateID. The view re-evaluates against
--   current source state on every materialization, so IsPlatformFTD
--   and IsGlobalFTD flow through automatically. To recover a wide
--   window (e.g. May 9–30), loop the SP per date.
--
-- IDEMPOTENT
--   Running for the same date twice produces the same output.
-- =====================================================================
CREATE OR REPLACE PROCEDURE main.de_output.sp_ddr_fact_mimo_allplatforms(p_date STRING)
SQL SECURITY INVOKER
LANGUAGE SQL
AS BEGIN
  DECLARE v_dateID INT;

  IF p_date IS NULL THEN
    SET v_dateID = CAST(DATE_FORMAT(DATE_SUB(CURRENT_DATE(), 1), 'yyyyMMdd') AS INT);
  ELSE
    SET v_dateID = CAST(p_date AS INT);
  END IF;

  --=================================================================
  -- PHASE 1 — daily incremental for TP + eMoney
  --=================================================================
  DELETE FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms
  WHERE DateID = v_dateID
    AND MIMOPlatform IN ('TradingPlatform', 'eMoney');

  INSERT INTO main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms
    (DateID, Date, RealCID, MIMOAction, OrigIdentifier, TransactionID,
     AmountUSD, AmountOrigCurrency, FundingTypeID, CurrencyID, Currency,
     IsPlatformFTD, IsInternalTransfer, IsRedeem, IsTradeFromIBAN, MIMOPlatform,
     IsGlobalFTD, UpdateDate, etr_y, etr_ym, etr_ymd,
     IsCryptoToFiat, IsRecurring, IsIBANQuickTransfer)
  SELECT
    DateID,
    CAST(Date AS TIMESTAMP),
    RealCID,
    MIMOAction,
    OrigIdentifier,
    TRY_CAST(TransactionID AS INT),
    CAST(AmountUSD AS DECIMAL(16,6)),
    CAST(AmountOrigCurrency AS DECIMAL(16,6)),
    FundingTypeID,
    CurrencyID,
    Currency,
    IsPlatformFTD,
    IsInternalTransfer,
    IsRedeem,
    IsTradeFromIBAN,
    MIMOPlatform,
    IsGlobalFTD,
    UpdateDate,
    DATE_FORMAT(Date, 'yyyy'),
    DATE_FORMAT(Date, 'yyyy-MM'),
    DATE_FORMAT(Date, 'yyyy-MM-dd'),
    IsCryptoToFiat,
    IsRecurring,
    IsIBANQuickTransfer
  FROM main.etoro_kpi_prep.v_mimo_allplatforms
  WHERE DateID = v_dateID
    AND MIMOPlatform IN ('TradingPlatform', 'eMoney');

  --=================================================================
  -- PHASE 2 — Options full refresh
  --=================================================================
  DELETE FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms
  WHERE MIMOPlatform = 'Options';

  INSERT INTO main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms
    (DateID, Date, RealCID, MIMOAction, OrigIdentifier, TransactionID,
     AmountUSD, AmountOrigCurrency, FundingTypeID, CurrencyID, Currency,
     IsPlatformFTD, IsInternalTransfer, IsRedeem, IsTradeFromIBAN, MIMOPlatform,
     IsGlobalFTD, UpdateDate, etr_y, etr_ym, etr_ymd,
     IsCryptoToFiat, IsRecurring, IsIBANQuickTransfer)
  SELECT
    DateID,
    CAST(Date AS TIMESTAMP),
    RealCID,
    MIMOAction,
    OrigIdentifier,
    TRY_CAST(TransactionID AS INT),
    CAST(AmountUSD AS DECIMAL(16,6)),
    CAST(AmountOrigCurrency AS DECIMAL(16,6)),
    FundingTypeID,
    CurrencyID,
    Currency,
    IsPlatformFTD,
    IsInternalTransfer,
    IsRedeem,
    IsTradeFromIBAN,
    MIMOPlatform,
    IsGlobalFTD,
    UpdateDate,
    DATE_FORMAT(Date, 'yyyy'),
    DATE_FORMAT(Date, 'yyyy-MM'),
    DATE_FORMAT(Date, 'yyyy-MM-dd'),
    IsCryptoToFiat,
    IsRecurring,
    IsIBANQuickTransfer
  FROM main.etoro_kpi_prep.v_mimo_allplatforms
  WHERE MIMOPlatform = 'Options';

  --=================================================================
  -- PHASE 3 — MoneyFarm full refresh
  --=================================================================
  DELETE FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms
  WHERE MIMOPlatform = 'MoneyFarm';

  INSERT INTO main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms
    (DateID, Date, RealCID, MIMOAction, OrigIdentifier, TransactionID,
     AmountUSD, AmountOrigCurrency, FundingTypeID, CurrencyID, Currency,
     IsPlatformFTD, IsInternalTransfer, IsRedeem, IsTradeFromIBAN, MIMOPlatform,
     IsGlobalFTD, UpdateDate, etr_y, etr_ym, etr_ymd,
     IsCryptoToFiat, IsRecurring, IsIBANQuickTransfer)
  SELECT
    DateID,
    CAST(Date AS TIMESTAMP),
    RealCID,
    MIMOAction,
    OrigIdentifier,
    TRY_CAST(TransactionID AS INT),
    CAST(AmountUSD AS DECIMAL(16,6)),
    CAST(AmountOrigCurrency AS DECIMAL(16,6)),
    FundingTypeID,
    CurrencyID,
    Currency,
    IsPlatformFTD,
    IsInternalTransfer,
    IsRedeem,
    IsTradeFromIBAN,
    MIMOPlatform,
    IsGlobalFTD,
    UpdateDate,
    DATE_FORMAT(Date, 'yyyy'),
    DATE_FORMAT(Date, 'yyyy-MM'),
    DATE_FORMAT(Date, 'yyyy-MM-dd'),
    IsCryptoToFiat,
    IsRecurring,
    IsIBANQuickTransfer
  FROM main.etoro_kpi_prep.v_mimo_allplatforms
  WHERE MIMOPlatform = 'MoneyFarm';
END;
