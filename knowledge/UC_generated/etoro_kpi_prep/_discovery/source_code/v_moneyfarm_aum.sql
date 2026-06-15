-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.etoro_kpi_prep.v_moneyfarm_aum
-- Captured: 2026-05-19T12:14:28Z
-- ==========================================================================

WITH daily_portfolio_balances AS (
  SELECT 
    etr_ymd AS date,
    GCID,
    Portfolio_Id AS PortfolioID,
    Product,
    CAST(Market_Value AS DOUBLE) AS market_value
  FROM main.money_farm.silver_moneyfarm_etoro_mf_aum
  WHERE GCID IS NOT NULL
),

gbp_usd_rates AS (
  SELECT 
    CAST(OccurredDate AS DATE) AS rate_date,
    (Ask + Bid) / 2 AS gbp_to_usd_rate
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit
  WHERE InstrumentID = 2
),

aggregated_balances AS (
  SELECT 
    date,
    GCID,
    SUM(market_value) AS total_balance_gbp,
    COUNT(DISTINCT PortfolioID) AS portfolio_count
  FROM daily_portfolio_balances
  GROUP BY date, GCID
)

SELECT 
  a.date,
  CAST(DATE_FORMAT(a.date, 'yyyyMMdd') AS INT) AS dateid,
  a.GCID as gcid,
  a.total_balance_gbp,
  a.total_balance_gbp * COALESCE(r.gbp_to_usd_rate, 0) AS total_balance_usd,
  CASE 
    WHEN a.total_balance_gbp > 0 THEN TRUE 
    ELSE FALSE 
  END AS is_funded,
  a.portfolio_count
FROM aggregated_balances a
LEFT JOIN gbp_usd_rates r
  ON a.date = r.rate_date
