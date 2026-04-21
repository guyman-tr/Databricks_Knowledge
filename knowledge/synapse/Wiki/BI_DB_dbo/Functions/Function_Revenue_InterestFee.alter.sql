-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.Function_Revenue_InterestFee
-- Generated: 2026-04-12 | recreate_views_with_col_comments.py
-- UC Target: main.etoro_kpi_prep.v_revenue_interestfee
-- Col comments: 3 added, 2 preserved (existing), 0 unmatched
-- NOTE: Column comments on views require CREATE OR REPLACE VIEW (not ALTER COLUMN).
-- =============================================================================

-- ---- Full CREATE OR REPLACE VIEW (idempotent — safe to re-run) ----
CREATE OR REPLACE VIEW main.etoro_kpi_prep.v_revenue_interestfee (
  RealCID COMMENT 'Real-account Customer ID. HASH distribution key. References Dim_Customer.RealCID. Always include in WHERE/JOIN for optimal performance.',
  GCID COMMENT 'Direct pass-through from Fact_SnapshotCustomer.GCID. (T1 — Function_Revenue_InterestFee)',
  DateID COMMENT 'Date of action as YYYYMMDD integer. Derived from Occurred. Part of nonclustered indexes — key filter column.',
  InterestFee COMMENT 'Direct (exposed as InterestFee). Source: BI_DB_Daily_CreditLine.DailyFee. (T1 — Function_Revenue_InterestFee)',
  IsValidCustomer COMMENT 'Direct pass-through from Fact_SnapshotCustomer.IsValidCustomer. (T1 — Function_Revenue_InterestFee)'
)
COMMENT 'BI_DB_dbo.Function_Revenue_InterestFee > Returns daily credit-line interest fees charged to customers (Daily_CreditLine.DailyFee as InterestFee), aligned to snapshot customer attributes via Dim_Range for the action date. Supports optional filtering to valid customers only.'
TBLPROPERTIES (
  'comment' = 'BI_DB_dbo.Function_Revenue_InterestFee > Returns daily credit-line interest fees charged to customers (Daily_CreditLine.DailyFee as InterestFee), aligned to snapshot customer attributes via Dim_Range for the action date. Supports optional filtering to valid customers only.')
WITH SCHEMA COMPENSATION
AS SELECT
    fca.RealCID,
    fsc.GCID,
    fca.DateID,
    fca.DailyFee AS InterestFee,
    fsc.IsValidCustomer
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_daily_creditline fca
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked fsc
    ON fca.RealCID = fsc.RealCID
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range dr
    ON fsc.DateRangeID = dr.DateRangeID
    AND fca.DateID BETWEEN dr.FromDateID AND dr.ToDateID

;
