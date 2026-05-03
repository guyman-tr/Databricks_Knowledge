-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.Function_Revenue_AdminFee
-- Generated: 2026-04-12 | recreate_views_with_col_comments.py
-- UC Target: main.etoro_kpi_prep.v_revenue_adminfee
-- Col comments: 7 added, 1 preserved (existing), 0 unmatched
-- NOTE: Column comments on views require CREATE OR REPLACE VIEW (not ALTER COLUMN).
-- =============================================================================

-- ---- Full CREATE OR REPLACE VIEW (idempotent - safe to re-run) ----
CREATE OR REPLACE VIEW main.etoro_kpi_prep.v_revenue_adminfee (
  PositionID COMMENT 'Direct pass-through from BI_DB_Fact_Customer_Action_Position_Distribution.PositionID. (T1 - Function_Revenue_AdminFee)',
  RealCID COMMENT 'Direct pass-through from BI_DB_Fact_Customer_Action_Position_Distribution.RealCID. (T1 - Function_Revenue_AdminFee)',
  DateID COMMENT 'Direct pass-through from BI_DB_Fact_Customer_Action_Position_Distribution.DateID. (T1 - Function_Revenue_AdminFee)',
  Occurred COMMENT 'UTC timestamp when action occurred. For position opens: open time. For logins: login time. For credits: credit record time.',
  AdminFee COMMENT '-1 * Amount WHERE ActionTypeID IN (36) AND CompensationReasonID = 117. Source: BI_DB_Fact_Customer_Action_Position_Distribution.Amount. (T2 - Function_Revenue_AdminFee)',
  IsSettled COMMENT 'Direct pass-through from BI_DB_Fact_Customer_Action_Position_Distribution.IsSettled. (T1 - Function_Revenue_AdminFee)',
  MirrorID COMMENT 'Direct pass-through from BI_DB_Fact_Customer_Action_Position_Distribution.MirrorID. (T1 - Function_Revenue_AdminFee)',
  SettlementTypeID COMMENT 'Direct pass-through from BI_DB_Fact_Customer_Action_Position_Distribution.SettlementTypeID. (T1 - Function_Revenue_AdminFee)'
)
COMMENT 'BI_DB_dbo.Function_Revenue_AdminFee > Returns administration fee revenue at position grain from BI_DB_Fact_Customer_Action_Position_Distribution where ActionTypeID IN (36) and CompensationReasonID = 117. The output metric AdminFee is -1 × Amount (sign convention). Rows include instrument type, copy/margin/SQF flags from Dim_Instrument and Function_Instrument_Snapshot_Enriched(@edateInt).'
TBLPROPERTIES (
  'comment' = 'BI_DB_dbo.Function_Revenue_AdminFee > Returns administration fee revenue at position grain from BI_DB_Fact_Customer_Action_Position_Distribution where ActionTypeID IN (36) and CompensationReasonID = 117. The output metric AdminFee is -1 × Amount (sign convention). Rows include instrument type, copy/margin/SQF flags from Dim_Instrument and Function_Instrument_Snapshot_Enriched(@edateInt).')
WITH SCHEMA COMPENSATION
AS SELECT
  CAST(fca.PositionID AS BIGINT) as PositionID,
  CAST(fca.RealCID AS INT) as RealCID,
  CAST(fca.DateID AS INT) as DateID,
  fca.Occurred,
  CAST(-1 * fca.Amount AS DECIMAL(38, 6)) AS AdminFee,
  CAST(fca.IsSettled AS INT) as IsSettled,
  CAST(fca.MirrorID AS INT) as MirrorID,
  CAST(fca.SettlementTypeID AS INT) as SettlementTypeID
FROM
  main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution fca
WHERE
  fca.ActionTypeID IN (36)
  AND fca.CompensationReasonID = 117

;
