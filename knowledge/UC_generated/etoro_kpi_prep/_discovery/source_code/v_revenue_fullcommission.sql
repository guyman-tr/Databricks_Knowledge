-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.etoro_kpi_prep.v_revenue_fullcommission
-- Captured: 2026-05-19T12:22:36Z
-- ==========================================================================

SELECT
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
