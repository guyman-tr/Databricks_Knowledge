-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.Function_Revenue_CashoutFee_ExcludeRedeem
-- Generated: 2026-04-12 | recreate_views_with_col_comments.py
-- UC Target: main.etoro_kpi_prep.v_revenue_cashoutfee_excluderedeem
-- Col comments: 2 added, 4 preserved (existing), 0 unmatched
-- NOTE: Column comments on views require CREATE OR REPLACE VIEW (not ALTER COLUMN).
-- =============================================================================

-- ---- Full CREATE OR REPLACE VIEW (idempotent — safe to re-run) ----
CREATE OR REPLACE VIEW main.etoro_kpi_prep.v_revenue_cashoutfee_excluderedeem (
  RealCID COMMENT 'Real-account Customer ID. HASH distribution key. References Dim_Customer.RealCID. Always include in WHERE/JOIN for optimal performance.',
  GCID COMMENT 'Direct pass-through from Fact_SnapshotCustomer.GCID. (T1 — Function_Revenue_CashoutFee_ExcludeRedeem)',
  DateID COMMENT 'Date of action as YYYYMMDD integer. Derived from Occurred. Part of nonclustered indexes — key filter column.',
  Occurred COMMENT 'UTC timestamp when action occurred. For position opens: open time. For logins: login time. For credits: credit record time.',
  CashoutFeeExcludeRedeem COMMENT 'eToro markup (spread) at position open in USD. 0 for non-position events. Same meaning as Dim_Position.Commission.',
  IsValidCustomer COMMENT 'Direct pass-through from Fact_SnapshotCustomer.IsValidCustomer. (T1 — Function_Revenue_CashoutFee_ExcludeRedeem)'
)
COMMENT 'BI_DB_dbo.Function_Revenue_CashoutFee_ExcludeRedeem > Returns cashout fee (Fact_CustomerAction.Commission) for ActionTypeID IN (30) with ISNULL(IsRedeem, 0) = 0 (cashout fees excluding redeem flows). Customer attributes come from Fact_SnapshotCustomer aligned to the action date via Dim_Range.'
TBLPROPERTIES (
  'comment' = 'BI_DB_dbo.Function_Revenue_CashoutFee_ExcludeRedeem > Returns cashout fee (Fact_CustomerAction.Commission) for ActionTypeID IN (30) with ISNULL(IsRedeem, 0) = 0 (cashout fees excluding redeem flows). Customer attributes come from Fact_SnapshotCustomer aligned to the action date via Dim_Range.')
WITH SCHEMA COMPENSATION
AS SELECT
    fca.RealCID,
    fsc.GCID,
    fca.DateID,
    fca.Occurred,
    fca.Commission AS CashoutFeeExcludeRedeem,
    fsc.IsValidCustomer
FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction fca
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked fsc
    ON fca.RealCID = fsc.RealCID
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range dr
    ON fsc.DateRangeID = dr.DateRangeID
    AND fca.DateID BETWEEN dr.FromDateID AND dr.ToDateID
WHERE fca.ActionTypeID = 30
    AND COALESCE(fca.IsRedeem, 0) = 0

;
