-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.etoro_kpi.ddr_customer_dailystatus
-- Captured: 2026-05-19T15:10:09Z
-- ==========================================================================

SELECT
  STRING(s.RealCID) AS RealCID,
  s.FromDateID,
  s.ToDateID,
  s.IsFunded,
  s.ActiveTraded AS IsActiveTrade,
  s.BalanceOnlyAccount AS BalanceOnly,
  CAST(s.Portfolio_Only AS INT) AS PortfolioOnly,
  s.IsChurned AS IsChurn,
  s.IsWinBack AS IsWinback
FROM main.etoro_kpi_prep.gold_de_user_dim_ddr_customer_dailystatus_scd AS s
