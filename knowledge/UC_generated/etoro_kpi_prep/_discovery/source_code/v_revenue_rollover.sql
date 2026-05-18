-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.etoro_kpi_prep.v_revenue_rollover
-- Captured: 2026-05-18T08:13:21Z
-- ==========================================================================

SELECT
  CAST(PositionID AS BIGINT) as PositionID,
  CAST(RealCID AS INT) as RealCID,
  fca.Occurred,
  CAST(DateID AS INT) as DateID,
  fca.etr_ymd,
  CAST(-1 * Amount AS DECIMAL(38, 6)) AS RolloverFee
FROM
  main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction fca
WHERE
  fca.ActionTypeID = 35
  AND fca.IsFeeDividend = 1
