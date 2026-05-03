-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.Function_Revenue_SpotAdjustFee
-- Generated: 2026-04-12 | recreate_views_with_col_comments.py
-- UC Target: main.etoro_kpi_prep.v_revenue_spotadjustfee
-- Col comments: 4 added, 4 preserved (existing), 1 unmatched
-- NOTE: Column comments on views require CREATE OR REPLACE VIEW (not ALTER COLUMN).
-- =============================================================================

-- ---- Full CREATE OR REPLACE VIEW (idempotent - safe to re-run) ----
CREATE OR REPLACE VIEW main.etoro_kpi_prep.v_revenue_spotadjustfee (
  PositionID COMMENT 'Direct pass-through from BI_DB_Fact_Customer_Action_Position_Distribution.PositionID. (T1 - Function_Revenue_SpotAdjustFee)',
  RealCID COMMENT 'Direct pass-through from BI_DB_Fact_Customer_Action_Position_Distribution.RealCID. (T1 - Function_Revenue_SpotAdjustFee)',
  Occurred COMMENT 'UTC timestamp when action occurred. For position opens: open time. For logins: login time. For credits: credit record time.',
  DateID COMMENT 'Direct pass-through from BI_DB_Fact_Customer_Action_Position_Distribution.DateID. (T1 - Function_Revenue_SpotAdjustFee)',
  etr_ymd,
  SpotAdjustFee COMMENT '-1 * Amount WHERE ActionTypeID = 36 AND CompensationReasonID = 118. Source: BI_DB_Fact_Customer_Action_Position_Distribution.Amount. (T2 - Function_Revenue_SpotAdjustFee)',
  IsSettled COMMENT 'Real ownership flag: 1=settled (owns asset), 0=CFD. NULL for non-position events. ETL fallback: IsBuy=1 AND Leverage=1 AND InstrumentTypeID IN (10,5,6) => 1. Same meaning as Dim_Position.IsSettled.',
  MirrorID COMMENT 'Copy-trade relationship ID. 0=manual action, >0=copy-trade. Same meaning as Dim_Position.MirrorID.',
  SettlementTypeID COMMENT 'Settlement mechanism: 0=CFD, 1=Real asset, 2=TRS, 3=CMT (crypto settled), 4=REAL_FUTURES, 5=MARGIN_TRADE. NULL for non-position events. Same meaning as Dim_Position.SettlementTypeID.'
)
COMMENT 'BI_DB_dbo.Function_Revenue_SpotAdjustFee > Returns spot-adjustment fee revenue (ActionTypeID 36, CompensationReasonID 118) from the customer action position distribution, negating Amount as SpotAdjustFee, with instrument type, SQF, copy, and margin attributes for analytics consistent with other trading fee TVFs.'
TBLPROPERTIES (
  'comment' = 'BI_DB_dbo.Function_Revenue_SpotAdjustFee > Returns spot-adjustment fee revenue (ActionTypeID 36, CompensationReasonID 118) from the customer action position distribution, negating Amount as SpotAdjustFee, with instrument type, SQF, copy, and margin attributes for analytics consistent with other trading fee TVFs.')
WITH SCHEMA COMPENSATION
AS SELECT
  CAST(PositionID AS BIGINT) as PositionID,
  CAST(RealCID AS INT) as RealCID,
  fca.Occurred,
  CAST(DateID AS INT) as DateID,
  fca.etr_ymd,
  CAST(-1 * Amount AS DECIMAL(38, 6)) AS SpotAdjustFee,
  fca.IsSettled,
  fca.MirrorID,
  fca.SettlementTypeID
FROM
  main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution fca
WHERE
  fca.ActionTypeID IN (36)
  AND fca.CompensationReasonID = 118

;
