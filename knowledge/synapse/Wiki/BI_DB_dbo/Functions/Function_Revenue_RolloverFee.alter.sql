-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.Function_Revenue_RolloverFee
-- Generated: 2026-04-12 | recreate_views_with_col_comments.py
-- UC Target: main.etoro_kpi_prep.v_revenue_rollover
-- Col comments: 4 added, 1 preserved (existing), 1 unmatched
-- NOTE: Column comments on views require CREATE OR REPLACE VIEW (not ALTER COLUMN).
-- =============================================================================

-- ---- Full CREATE OR REPLACE VIEW (idempotent — safe to re-run) ----
CREATE OR REPLACE VIEW main.etoro_kpi_prep.v_revenue_rollover (
  PositionID COMMENT 'Direct pass-through from BI_DB_Fact_Customer_Action_Position_Distribution.PositionID. (T1 — Function_Revenue_RolloverFee)',
  RealCID COMMENT 'Direct pass-through from BI_DB_Fact_Customer_Action_Position_Distribution.RealCID. (T1 — Function_Revenue_RolloverFee)',
  Occurred COMMENT 'UTC timestamp when action occurred. For position opens: open time. For logins: login time. For credits: credit record time.',
  DateID COMMENT 'Direct pass-through from BI_DB_Fact_Customer_Action_Position_Distribution.DateID. (T1 — Function_Revenue_RolloverFee)',
  etr_ymd,
  RolloverFee COMMENT '-1 * Amount WHERE ActionTypeID = 35 AND IsFeeDividend = 1. Source: BI_DB_Fact_Customer_Action_Position_Distribution.Amount. (T2 — Function_Revenue_RolloverFee)'
)
COMMENT 'BI_DB_dbo.Function_Revenue_RolloverFee > Returns overnight rollover fee revenue from BI_DB_Fact_Customer_Action_Position_Distribution (ActionTypeID 35, IsFeeDividend 1), negating Amount as RolloverFee, enriched with instrument type, SQF flag, copy/margin indicators, and customer attributes carried on the distribution row.'
TBLPROPERTIES (
  'comment' = 'BI_DB_dbo.Function_Revenue_RolloverFee > Returns overnight rollover fee revenue from BI_DB_Fact_Customer_Action_Position_Distribution (ActionTypeID 35, IsFeeDividend 1), negating Amount as RolloverFee, enriched with instrument type, SQF flag, copy/margin indicators, and customer attributes carried on the distribution row.')
WITH SCHEMA COMPENSATION
AS SELECT
  CAST(PositionID AS BIGINT) as PositionID,
  CAST(RealCID AS INT) as RealCID,
  fca.Occurred,
  CAST(DateID AS INT) as DateID,
  fca.etr_ymd,
  CAST(-1 * Amount AS DECIMAL(38, 6)) AS RolloverFee
FROM
  main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction fca
WHERE
  fca.ActionTypeID = 35
  AND fca.IsFeeDividend = 1

;
