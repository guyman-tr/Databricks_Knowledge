-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.Function_Revenue_Commissions
-- Generated: 2026-04-12 | recreate_views_with_col_comments.py
-- UC Target: main.etoro_kpi_prep.v_revenue_commission
-- Col comments: 9 added, 1 preserved (existing), 5 unmatched
-- NOTE: Column comments on views require CREATE OR REPLACE VIEW (not ALTER COLUMN).
-- =============================================================================

-- ---- Full CREATE OR REPLACE VIEW (idempotent — safe to re-run) ----
CREATE OR REPLACE VIEW main.etoro_kpi_prep.v_revenue_commission (
  PositionID COMMENT 'Direct pass-through from Fact_CustomerAction.PositionID. (T1 — Function_Revenue_Commissions)',
  RealCID COMMENT 'Direct pass-through from Fact_CustomerAction.RealCID. (T1 — Function_Revenue_Commissions)',
  DateID COMMENT 'Direct pass-through from Fact_CustomerAction.DateID. (T1 — Function_Revenue_Commissions)',
  Occurred COMMENT 'UTC timestamp when action occurred. For position opens: open time. For logins: login time. For credits: credit record time.',
  etr_ymd,
  Commission,
  CommissionOnClose COMMENT 'CASE WHEN ActionTypeID IN (4,5,6,28,40) THEN CommissionOnClose ELSE 0 END (same prep filter). Source: Fact_CustomerAction.CommissionOnClose. (T2 — Function_Revenue_Commissions)',
  CommissionByUnits,
  ActionTypeID COMMENT 'Direct pass-through from Fact_CustomerAction.ActionTypeID. (T1 — Function_Revenue_Commissions)',
  ActionType,
  IsActiveTrade,
  IsSettled COMMENT 'Direct pass-through from Fact_CustomerAction.IsSettled. (T1 — Function_Revenue_Commissions)',
  MirrorID COMMENT 'Direct pass-through from Fact_CustomerAction.MirrorID. (T1 — Function_Revenue_Commissions)',
  SettlementTypeID COMMENT 'Direct pass-through from Fact_CustomerAction.SettlementTypeID. (T1 — Function_Revenue_Commissions)',
  TotalCommission COMMENT 'CASE WHEN ActionTypeID IN (1,2,3,39) THEN CommissionOnOpen WHEN ActionTypeID IN (4,5,6,28,40) THEN CommissionCloseAdjustment END (same prep filter). Source: Fact_CustomerAction.Commission, CommissionOnClose, CommissionByUnits. (T2 — Function_Revenue_Commissions)'
)
COMMENT 'BI_DB_dbo.Function_Revenue_Commissions > Returns trading commission components by customer action from Fact_CustomerAction where the first CTE restricts rows to ActionTypeID IN (1,2,3,39,4,5,6,28,40) (open-style vs close-style families). It joins snapshot context and Dim_Instrument. CommissionOnOpen applies when ActionTypeID IN (1,2,3,39); CommissionOnClose / CommissionCloseAdjustment apply when ActionTypeID IN (4,5,6,28,40) (close adjustment uses CommissionOnClose - CommissionByUnits). TotalCommission selects open vs close branch by the same groupings. Adds copy and margin flags and IsSQF via Function_Instrument_Snapshot_Enriched(@edateInt).'
TBLPROPERTIES (
  'comment' = 'BI_DB_dbo.Function_Revenue_Commissions > Returns trading commission components by customer action from Fact_CustomerAction where the first CTE restricts rows to ActionTypeID IN (1,2,3,39,4,5,6,28,40) (open-style vs close-style families). It joins snapshot context and Dim_Instrument. CommissionOnOpen applies when ActionTypeID IN (1,2,3,39); CommissionOnClose / CommissionCloseAdjustment apply when ActionTypeID IN (4,5,6,28,40) (close adjustment uses CommissionOnClose - CommissionByUnits). TotalCommission selects open vs close branch by the same groupings. Adds copy and margin flags and IsSQF via Function_Instrument_Snapshot_Enriched(@edateInt).')
WITH SCHEMA COMPENSATION
AS SELECT
  CAST(fca.PositionID AS BIGINT) as PositionID,
  CAST(fca.RealCID AS INT) as RealCID,
  CAST(fca.DateID AS INT) as DateID,
  fca.Occurred,
  fca.etr_ymd,
  CAST(fca.Commission AS DECIMAL(38, 6)) as Commission,
  CAST(fca.CommissionOnClose AS DECIMAL(38, 6)) as CommissionOnClose,
  CAST(fca.CommissionByUnits AS DECIMAL(38, 6)) as CommissionByUnits,
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
      WHEN fca.ActionTypeID IN (1, 2, 3, 39) THEN fca.Commission
      WHEN
        fca.ActionTypeID IN (4, 5, 6, 28, 40)
      THEN
        (fca.CommissionOnClose - fca.CommissionByUnits)
      ELSE 0
    END AS DECIMAL(38, 6)
  ) AS TotalCommission
FROM
  main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction fca
WHERE
  fca.ActionTypeID IN (1, 2, 3, 39, 4, 5, 6, 28, 40)

;
