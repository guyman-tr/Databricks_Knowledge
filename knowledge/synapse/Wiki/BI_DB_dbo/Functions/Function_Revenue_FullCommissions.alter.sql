-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.Function_Revenue_FullCommissions
-- Generated: 2026-04-12 | recreate_views_with_col_comments.py
-- UC Target: main.etoro_kpi_prep.v_revenue_fullcommission
-- Col comments: 9 added, 1 preserved (existing), 5 unmatched
-- NOTE: Column comments on views require CREATE OR REPLACE VIEW (not ALTER COLUMN).
-- =============================================================================

-- ---- Full CREATE OR REPLACE VIEW (idempotent — safe to re-run) ----
CREATE OR REPLACE VIEW main.etoro_kpi_prep.v_revenue_fullcommission (
  PositionID COMMENT 'Direct pass-through from Fact_CustomerAction.PositionID. (T1 — Function_Revenue_FullCommissions)',
  RealCID COMMENT 'Direct pass-through from Fact_CustomerAction.RealCID. (T1 — Function_Revenue_FullCommissions)',
  DateID COMMENT 'Direct pass-through from Fact_CustomerAction.DateID. (T1 — Function_Revenue_FullCommissions)',
  Occurred COMMENT 'UTC timestamp when action occurred. For position opens: open time. For logins: login time. For credits: credit record time.',
  etr_ymd,
  FullCommission,
  FullCommissionOnClose COMMENT 'CASE WHEN ActionTypeID IN (4,5,6,28,40) THEN FullCommissionOnClose ELSE 0 END. Source: Fact_CustomerAction. (T2 — Function_Revenue_FullCommissions)',
  FullCommissionByUnits,
  ActionTypeID COMMENT 'Direct pass-through from Fact_CustomerAction.ActionTypeID. (T1 — Function_Revenue_FullCommissions)',
  ActionType,
  IsActiveTrade,
  IsSettled COMMENT 'Direct pass-through from Fact_CustomerAction.IsSettled. (T1 — Function_Revenue_FullCommissions)',
  MirrorID COMMENT 'Direct pass-through from Fact_CustomerAction.MirrorID. (T1 — Function_Revenue_FullCommissions)',
  SettlementTypeID COMMENT 'Direct pass-through from Fact_CustomerAction.SettlementTypeID. (T1 — Function_Revenue_FullCommissions)',
  TotalFullCommission COMMENT 'CASE WHEN ActionTypeID IN (1,2,3,39) THEN FullCommissionOnOpen WHEN ActionTypeID IN (4,5,6,28,40) THEN FullCommissionCloseAdjustment END. Source: Fact_CustomerAction. (T2 — Function_Revenue_FullCommissions)'
)
COMMENT 'BI_DB_dbo.Function_Revenue_FullCommissions > Returns full trading commission components (open, close, and close adjustment) per customer action and position, enriched with snapshot customer attributes and instrument type. Used to analyze commission revenue by action type, copy trading, margin settlement, and single-quote futures (SQF) instruments.'
TBLPROPERTIES (
  'comment' = 'BI_DB_dbo.Function_Revenue_FullCommissions > Returns full trading commission components (open, close, and close adjustment) per customer action and position, enriched with snapshot customer attributes and instrument type. Used to analyze commission revenue by action type, copy trading, margin settlement, and single-quote futures (SQF) instruments.')
WITH SCHEMA COMPENSATION
AS SELECT
  CAST(fca.PositionID AS BIGINT) as PositionID,
  CAST(fca.RealCID AS INT) as RealCID,
  CAST(fca.DateID AS INT) as DateID,
  fca.Occurred,
  fca.etr_ymd,
  CAST(fca.FullCommission AS DECIMAL(38, 6)) as FullCommission,
  CAST(fca.FullCommissionOnClose AS DECIMAL(38, 6)) as FullCommissionOnClose,
  CAST(fca.FullCommissionByUnits AS DECIMAL(38, 6)) as FullCommissionByUnits,
  CAST(fca.ActionTypeID AS INT) as ActionTypeID,
  CASE
    WHEN fca.ActionTypeID IN (1, 2, 3, 39) THEN 'Open'
    ELSE 'Close'
  END as ActionType,
  CASE
    WHEN
      fca.MirrorID > 0
      AND COALESCE(fca.IsAirdrop, 0) = 0
    THEN
      1
    ELSE 0
  END as IsActiveTrade,
  CAST(fca.IsSettled AS INT) as IsSettled,
  CAST(fca.MirrorID AS INT) as MirrorID,
  CAST(fca.SettlementTypeID AS INT) as SettlementTypeID,
  CAST(
    CASE
      WHEN fca.ActionTypeID IN (1, 2, 3, 39) THEN fca.FullCommission
      WHEN
        fca.ActionTypeID IN (4, 5, 6, 28, 40)
      THEN
        (fca.FullCommissionOnClose - fca.FullCommissionByUnits)
      ELSE 0
    END AS DECIMAL(38, 6)
  ) AS TotalFullCommission
FROM
  main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction fca
WHERE
  fca.ActionTypeID IN (1, 2, 3, 39, 4, 5, 6, 28, 40)

;
