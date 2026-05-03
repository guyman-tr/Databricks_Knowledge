-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.Function_Revenue_Share_Lending
-- Generated: 2026-04-12 | recreate_views_with_col_comments.py
-- UC Target: main.etoro_kpi_prep.v_revenue_share_lending
-- Col comments: 4 added, 5 preserved (existing), 0 unmatched
-- NOTE: Column comments on views require CREATE OR REPLACE VIEW (not ALTER COLUMN).
-- =============================================================================

-- ---- Full CREATE OR REPLACE VIEW (idempotent - safe to re-run) ----
CREATE OR REPLACE VIEW main.etoro_kpi_prep.v_revenue_share_lending (
  RealCID COMMENT 'Real-account Customer ID. HASH distribution key. References Dim_Customer.RealCID. Always include in WHERE/JOIN for optimal performance.',
  GCID COMMENT 'Direct pass-through from Fact_SnapshotCustomer.GCID. (T1 - Function_Revenue_Share_Lending)',
  DateID COMMENT 'Date of action as YYYYMMDD integer. Derived from Occurred. Part of nonclustered indexes - key filter column.',
  Occurred COMMENT 'UTC timestamp when action occurred. For position opens: open time. For logins: login time. For credits: credit record time.',
  ShareLendingFeeEtoroShare COMMENT 'Event amount in USD. For position opens: invested amount. For deposits: deposit amount. For fees: fee amount (negative).',
  ShareLendingFeeUserShare COMMENT 'Event amount in USD. For position opens: invested amount. For deposits: deposit amount. For fees: fee amount (negative).',
  ShareLendingFeeBrokerShare COMMENT 'Amount / ROUND(0.425,1,1) - 2 * Amount WHERE ActionTypeID = 36 AND CompensationReasonID = 119. Source: Fact_CustomerAction.Amount. (T2 - Function_Revenue_Share_Lending)',
  ShareLendingGrossAmount COMMENT '2 Amount + Amount / ROUND(0.425,1,1) - 2 Amount WHERE ActionTypeID = 36 AND CompensationReasonID = 119. Source: Fact_CustomerAction.Amount. (T2 - Function_Revenue_Share_Lending)',
  IsValidCustomer COMMENT 'Direct pass-through from Fact_SnapshotCustomer.IsValidCustomer. (T1 - Function_Revenue_Share_Lending)'
)
COMMENT 'BI_DB_dbo.Function_Revenue_Share_Lending > Surfaces share-lending compensation actions (ActionTypeID 36, CompensationReasonID 119) with customer snapshot attributes, splitting the booked Amount into eToro share, user share, inferred broker share, and gross using the BNY-style split formula (round(0.425,1,1)).'
TBLPROPERTIES (
  'comment' = 'BI_DB_dbo.Function_Revenue_Share_Lending > Surfaces share-lending compensation actions (ActionTypeID 36, CompensationReasonID 119) with customer snapshot attributes, splitting the booked Amount into eToro share, user share, inferred broker share, and gross using the BNY-style split formula (round(0.425,1,1)).')
WITH SCHEMA COMPENSATION
AS SELECT
    fca.RealCID,
    fsc.GCID,
    fca.DateID,
    fca.Occurred,
    fca.Amount  AS ShareLendingFeeEtoroShare,
    fca.Amount  AS ShareLendingFeeUserShare,
    fca.Amount / 0.4 - 2 * fca.Amount AS ShareLendingFeeBrokerShare,
    fca.Amount / 0.4                  AS ShareLendingGrossAmount,
    fsc.IsValidCustomer
FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction fca
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked fsc
    ON fca.RealCID = fsc.RealCID
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range dr
    ON fsc.DateRangeID = dr.DateRangeID
    AND fca.DateID BETWEEN dr.FromDateID AND dr.ToDateID
WHERE fca.ActionTypeID = 36
    AND fca.CompensationReasonID = 119

;
