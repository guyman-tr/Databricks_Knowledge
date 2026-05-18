-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.etoro_kpi_prep.v_revenue_ticketfee_bypercent
-- Captured: 2026-05-18T08:14:09Z
-- ==========================================================================

WITH
-- Period 1a: Before 20260308 - Open actions from history costs
before_20260308_open AS (
  SELECT DISTINCT
    CAST(fhc.PositionID AS BIGINT) AS PositionID,
    CAST(fcapd.RealCID AS INT) AS RealCID,
    fhc.Occurred,
    CAST(DATE_FORMAT(fhc.Occurred, 'yyyyMMdd') AS INT) AS DateID,
    CAST(CASE WHEN CAST(DATE_FORMAT(fhc.Occurred, 'yyyyMMdd') AS INT) < 20250525 THEN 0
              ELSE fhc.ValueInAccountCurrency END AS DECIMAL(38, 6)) AS TicketFeeByPercent,
    'Open' AS ActionType
  FROM main.general.bronze_historycosts_history_costs fhc
  JOIN main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution fcapd
    ON CAST(DATE_FORMAT(fhc.Occurred, 'yyyyMMdd') AS INT) = fcapd.DateID
    AND fhc.PositionID = fcapd.PositionID
    AND fcapd.TicketFeeAction = 'Open'
  WHERE fhc.OperationTypeID IN (14, 24)
    AND fhc.CostSubTypeID = 4
    AND fhc.CalculationTypeID IN (4, 7)
    AND COALESCE(fhc.ValueInAccountCurrency, 0) > 0
    AND CAST(DATE_FORMAT(fhc.Occurred, 'yyyyMMdd') AS INT) < 20260308
),

-- Period 1b: Before 20260308 - Close actions from history costs
before_20260308_close AS (
  SELECT DISTINCT
    CAST(fhc.PositionID AS BIGINT) AS PositionID,
    CAST(fcapd.RealCID AS INT) AS RealCID,
    fhc.Occurred,
    CAST(DATE_FORMAT(fhc.Occurred, 'yyyyMMdd') AS INT) AS DateID,
    CAST(CASE WHEN CAST(DATE_FORMAT(fhc.Occurred, 'yyyyMMdd') AS INT) < 20250525 THEN 0
              ELSE fhc.ValueInAccountCurrency END AS DECIMAL(38, 6)) AS TicketFeeByPercent,
    'Close' AS ActionType
  FROM main.general.bronze_historycosts_history_costs fhc
  JOIN main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution fcapd
    ON CAST(DATE_FORMAT(fhc.Occurred, 'yyyyMMdd') AS INT) = fcapd.DateID
    AND fhc.PositionID = fcapd.PositionID
    AND fcapd.TicketFeeAction = 'Close'
  WHERE fhc.OperationTypeID IN (12, 13)
    AND fhc.CostSubTypeID = 4
    AND fhc.CalculationTypeID IN (4, 7)
    AND COALESCE(fhc.ValueInAccountCurrency, 0) > 0
    AND CAST(DATE_FORMAT(fhc.Occurred, 'yyyyMMdd') AS INT) < 20260308
),

-- Period 2: After 20260308 - from distribution table, exclude instrument types 5/6 settled non-margin
after_20260308 AS (
  SELECT
    CAST(fca.PositionID AS BIGINT) AS PositionID,
    CAST(fca.RealCID AS INT) AS RealCID,
    fca.Occurred,
    CAST(fca.DateID AS INT) AS DateID,
    CAST(-1 * fca.Amount AS DECIMAL(38, 6)) AS TicketFeeByPercent,
    fca.TicketFeeAction AS ActionType
  FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution fca
  LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument di
    ON fca.InstrumentID = di.InstrumentID
  WHERE fca.ActionTypeID IN (35)
    AND fca.IsFeeDividend = 4
    AND fca.DateID >= 20260308
    AND (fca.TicketFeeAction IN ('Open', 'Close') OR fca.SettlementTypeID = 4)
    AND NOT (di.InstrumentTypeID IN (5, 6) AND fca.IsSettled = 1 AND fca.SettlementTypeID <> 5)
)

SELECT * FROM before_20260308_open
UNION ALL
SELECT * FROM before_20260308_close
UNION ALL
SELECT * FROM after_20260308
