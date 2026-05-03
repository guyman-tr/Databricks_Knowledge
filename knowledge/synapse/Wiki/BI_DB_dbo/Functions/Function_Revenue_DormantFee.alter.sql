-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.Function_Revenue_DormantFee
-- Generated: 2026-04-12 | recreate_views_with_col_comments.py
-- UC Target: main.etoro_kpi_prep.v_revenue_dormantfee
-- Col comments: 3 added, 3 preserved (existing), 0 unmatched
-- NOTE: Column comments on views require CREATE OR REPLACE VIEW (not ALTER COLUMN).
-- =============================================================================

-- ---- Full CREATE OR REPLACE VIEW (idempotent - safe to re-run) ----
CREATE OR REPLACE VIEW main.etoro_kpi_prep.v_revenue_dormantfee (
  RealCID COMMENT 'Real-account Customer ID. HASH distribution key. References Dim_Customer.RealCID. Always include in WHERE/JOIN for optimal performance.',
  GCID COMMENT 'Direct pass-through from Fact_SnapshotCustomer.GCID. (T1 - Function_Revenue_DormantFee)',
  DateID COMMENT 'Date of action as YYYYMMDD integer. Derived from Occurred. Part of nonclustered indexes - key filter column.',
  Occurred COMMENT 'UTC timestamp when action occurred. For position opens: open time. For logins: login time. For credits: credit record time.',
  DormantFee COMMENT '-1 * Amount WHERE ActionTypeID = 36 AND CompensationReasonID = 30. Source: Fact_CustomerAction.Amount. (T2 - Function_Revenue_DormantFee)',
  IsValidCustomer COMMENT 'Direct pass-through from Fact_SnapshotCustomer.IsValidCustomer. (T1 - Function_Revenue_DormantFee)'
)
COMMENT 'BI_DB_dbo.Function_Revenue_DormantFee > Returns dormant account fee revenue from Fact_CustomerAction where ActionTypeID = 36 and CompensationReasonID = 30, negating Amount as DormantFee. Customer attributes from Fact_SnapshotCustomer aligned via Dim_Range for the action date.'
TBLPROPERTIES (
  'comment' = 'BI_DB_dbo.Function_Revenue_DormantFee > Returns dormant account fee revenue from Fact_CustomerAction where ActionTypeID = 36 and CompensationReasonID = 30, negating Amount as DormantFee. Customer attributes from Fact_SnapshotCustomer aligned via Dim_Range for the action date.')
WITH SCHEMA COMPENSATION
AS SELECT
    fca.RealCID,
    fsc.GCID,
    fca.DateID,
    fca.Occurred,
    -1 * fca.Amount AS DormantFee,
    fsc.IsValidCustomer
FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction fca
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked fsc
    ON fca.RealCID = fsc.RealCID
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range dr
    ON fsc.DateRangeID = dr.DateRangeID
    AND fca.DateID BETWEEN dr.FromDateID AND dr.ToDateID
WHERE fca.ActionTypeID = 36
    AND fca.CompensationReasonID = 30

;
