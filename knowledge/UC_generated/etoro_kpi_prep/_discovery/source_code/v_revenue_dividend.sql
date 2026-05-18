-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.etoro_kpi_prep.v_revenue_dividend
-- Captured: 2026-05-18T08:12:36Z
-- ==========================================================================

SELECT
  CAST(PositionID AS BIGINT) as PositionID,
  CAST(RealCID AS INT) as RealCID,
  fca.Occurred,
  CAST(DateID AS INT) as DateID,
  etr_ymd,
  CAST(Amount AS DECIMAL(38, 6)) AS Dividend
FROM
  main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction fca
WHERE
  fca.ActionTypeID = 35
  AND fca.IsFeeDividend = 2
