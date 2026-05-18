-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.etoro_kpi_prep.v_revenue_ticketfee_fixed
-- Captured: 2026-05-18T08:14:20Z
-- ==========================================================================

WITH
-- Period 1: Before 20250525 - from distribution table
before_20250525 AS (
  SELECT
    CAST(fca.PositionID AS BIGINT) AS PositionID,
    CAST(fca.RealCID AS INT) AS RealCID,
    fca.Occurred,
    CAST(fca.DateID AS INT) AS DateID,
    CAST(-1 * fca.Amount AS DECIMAL(38, 6)) AS TicketFeeFixed,
    fca.TicketFeeAction AS ActionType
  FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution fca
  WHERE fca.ActionTypeID IN (35)
    AND fca.IsFeeDividend = 4
    AND fca.DateID < 20250525
),

-- Period 2a: 20250525 to 20260308 - Open actions from history costs
mid_period_open AS (
  SELECT DISTINCT
    CAST(fhc.PositionID AS BIGINT) AS PositionID,
    CAST(fcapd.RealCID AS INT) AS RealCID,
    fhc.Occurred,
    CAST(DATE_FORMAT(fhc.Occurred, 'yyyyMMdd') AS INT) AS DateID,
    CAST(fhc.ValueInAccountCurrency AS DECIMAL(38, 6)) AS TicketFeeFixed,
    'Open' AS ActionType
  FROM main.general.bronze_historycosts_history_costs fhc
  JOIN main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution fcapd
    ON CAST(DATE_FORMAT(fhc.Occurred, 'yyyyMMdd') AS INT) = fcapd.DateID
    AND fhc.PositionID = fcapd.PositionID
    AND fcapd.TicketFeeAction = 'Open'
  WHERE fhc.OperationTypeID IN (14, 24)
    AND fhc.CostSubTypeID IN (2, 6)
    AND fhc.CalculationTypeID IN (3, 8)
    AND COALESCE(fhc.ValueInAccountCurrency, 0) <> 0
    AND CAST(DATE_FORMAT(fhc.Occurred, 'yyyyMMdd') AS INT) >= 20250525
    AND CAST(DATE_FORMAT(fhc.Occurred, 'yyyyMMdd') AS INT) < 20260308
),

-- Period 2b: 20250525 to 20260308 - Close actions from history costs
mid_period_close AS (
  SELECT DISTINCT
    CAST(fhc.PositionID AS BIGINT) AS PositionID,
    CAST(fcapd.RealCID AS INT) AS RealCID,
    fhc.Occurred,
    CAST(DATE_FORMAT(fhc.Occurred, 'yyyyMMdd') AS INT) AS DateID,
    CAST(fhc.ValueInAccountCurrency AS DECIMAL(38, 6)) AS TicketFeeFixed,
    'Close' AS ActionType
  FROM main.general.bronze_historycosts_history_costs fhc
  JOIN main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution fcapd
    ON CAST(DATE_FORMAT(fhc.Occurred, 'yyyyMMdd') AS INT) = fcapd.DateID
    AND fhc.PositionID = fcapd.PositionID
    AND fcapd.TicketFeeAction = 'Close'
  WHERE fhc.OperationTypeID IN (12, 13)
    AND fhc.CostSubTypeID IN (2, 6)
    AND fhc.CalculationTypeID IN (3, 8)
    AND COALESCE(fhc.ValueInAccountCurrency, 0) <> 0
    AND CAST(DATE_FORMAT(fhc.Occurred, 'yyyyMMdd') AS INT) >= 20250525
    AND CAST(DATE_FORMAT(fhc.Occurred, 'yyyyMMdd') AS INT) < 20260308
),

-- Period 3: After 20260308 - back to distribution table with instrument filters
after_20260308 AS (
  SELECT
    CAST(fca.PositionID AS BIGINT) AS PositionID,
    CAST(fca.RealCID AS INT) AS RealCID,
    fca.Occurred,
    CAST(fca.DateID AS INT) AS DateID,
    CAST(-1 * fca.Amount AS DECIMAL(38, 6)) AS TicketFeeFixed,
    fca.TicketFeeAction AS ActionType
  FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution fca
  LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument di
    ON fca.InstrumentID = di.InstrumentID
  WHERE fca.ActionTypeID IN (35)
    AND fca.IsFeeDividend = 4
    AND fca.DateID >= 20260308
    AND (di.InstrumentTypeID IN (5, 6) AND fca.IsSettled = 1 AND fca.SettlementTypeID <> 5)
    AND (fca.TicketFeeAction IN ('Open', 'Close') OR fca.SettlementTypeID = 4)
)

SELECT * FROM before_20250525
UNION ALL
SELECT * FROM mid_period_open
UNION ALL
SELECT * FROM mid_period_close
UNION ALL
SELECT * FROM after_20260308
