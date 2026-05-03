-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.Function_Revenue_Dividend
-- Generated: 2026-04-12 | recreate_views_with_col_comments.py
-- UC Target: main.etoro_kpi_prep.v_revenue_dividend
-- Col comments: 4 added, 1 preserved (existing), 1 unmatched
-- NOTE: Column comments on views require CREATE OR REPLACE VIEW (not ALTER COLUMN).
-- =============================================================================

-- ---- Full CREATE OR REPLACE VIEW (idempotent - safe to re-run) ----
CREATE OR REPLACE VIEW main.etoro_kpi_prep.v_revenue_dividend (
  PositionID COMMENT 'Direct pass-through from BI_DB_Fact_Customer_Action_Position_Distribution.PositionID. (T1 - Function_Revenue_Dividend)',
  RealCID COMMENT 'Direct pass-through from BI_DB_Fact_Customer_Action_Position_Distribution.RealCID. (T1 - Function_Revenue_Dividend)',
  Occurred COMMENT 'UTC timestamp when action occurred. For position opens: open time. For logins: login time. For credits: credit record time.',
  DateID COMMENT 'Direct pass-through from BI_DB_Fact_Customer_Action_Position_Distribution.DateID. (T1 - Function_Revenue_Dividend)',
  etr_ymd,
  Dividend COMMENT 'Amount WHERE ActionTypeID IN (35) AND IsFeeDividend = 2. Source: BI_DB_Fact_Customer_Action_Position_Distribution.Amount. (T2 - Function_Revenue_Dividend)'
)
COMMENT 'BI_DB_dbo.Function_Revenue_Dividend > Returns dividend fee revenue rows from the distributed customer-action fact for ActionTypeID 35 with IsFeeDividend = 2, enriched with instrument type/future flags and copy/margin indicators for analytics.'
TBLPROPERTIES (
  'comment' = 'BI_DB_dbo.Function_Revenue_Dividend > Returns dividend fee revenue rows from the distributed customer-action fact for ActionTypeID 35 with IsFeeDividend = 2, enriched with instrument type/future flags and copy/margin indicators for analytics.')
WITH SCHEMA COMPENSATION
AS SELECT
  CAST(PositionID AS BIGINT) as PositionID,
  CAST(RealCID AS INT) as RealCID,
  fca.Occurred,
  CAST(DateID AS INT) as DateID,
  etr_ymd,
  CAST(Amount AS DECIMAL(38, 6)) AS Dividend
FROM
  main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction fca
WHERE
  fca.ActionTypeID = 35
  AND fca.IsFeeDividend = 2

;
