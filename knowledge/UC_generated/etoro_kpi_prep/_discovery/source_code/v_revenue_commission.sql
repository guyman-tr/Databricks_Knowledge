-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.etoro_kpi_prep.v_revenue_commission
-- Captured: 2026-05-18T08:11:21Z
-- ==========================================================================

SELECT
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
