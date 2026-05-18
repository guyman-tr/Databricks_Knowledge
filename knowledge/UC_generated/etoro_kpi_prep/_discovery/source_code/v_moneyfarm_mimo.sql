-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.etoro_kpi_prep.v_moneyfarm_mimo
-- Captured: 2026-05-18T08:07:03Z
-- ==========================================================================

WITH raw_events AS (
  SELECT 
    EventPayloadRowData.EventMetadata.Gcid as GCID,
    EventPayloadRowData.EventMetadata.EventType as event_type,
    EventPayloadRowData.EventMetadata.CreatedAt as created_at,
    EventPayloadRowData.EventData as event_data_json
  FROM main.compliance.bronze_event_hub_prod_event_streaming_we_sub_accounts
  WHERE EventPayloadRowData.ProviderName = 'Moneyfarm'
    AND EventPayloadRowData.EventMetadata.EventType IN ('PORTFOLIO_DEPOSIT', 'PORTFOLIO_WITHDRAW')
    AND EventPayloadRowData.EventMetadata.Gcid IS NOT NULL
),

parsed_events AS (
  SELECT 
    GCID,
    event_type,
    CAST(SUBSTRING(created_at, 1, 10) AS DATE) AS date,
    CAST(get_json_object(get_json_object(event_data_json, '$.data'), '$.amount') AS DOUBLE) AS amount,
    get_json_object(get_json_object(event_data_json, '$.data'), '$.portfolioId') AS portfolio_id,
    get_json_object(get_json_object(event_data_json, '$.data'), '$.valueDate') AS value_date
  FROM raw_events
),

mimo_daily AS (
  SELECT 
    date,
    GCID,
    SUM(CASE WHEN event_type = 'PORTFOLIO_DEPOSIT' AND amount > 0 THEN amount ELSE 0 END) AS total_deposits,
    SUM(CASE WHEN event_type = 'PORTFOLIO_WITHDRAW' AND amount < 0 THEN ABS(amount) ELSE 0 END) AS total_withdrawals,
    SUM(CASE WHEN event_type = 'PORTFOLIO_DEPOSIT' AND amount > 0 THEN 1 ELSE 0 END) AS count_deposits,
    SUM(CASE WHEN event_type = 'PORTFOLIO_WITHDRAW' AND amount < 0 THEN 1 ELSE 0 END) AS count_withdrawals
  FROM parsed_events
  GROUP BY date, GCID
),

first_deposit_dates AS (
  SELECT 
    GCID,
    MIN(date) AS first_deposit_date
  FROM mimo_daily
  WHERE total_deposits > 0
  GROUP BY GCID
),

gbp_usd_rates AS (
  SELECT 
    CAST(OccurredDate AS DATE) AS rate_date,
    (Ask + Bid) / 2 AS gbp_to_usd_rate
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit
  WHERE InstrumentID = 2
)

SELECT 
  m.date,
  CAST(DATE_FORMAT(m.date, 'yyyyMMdd') AS INT) AS dateid,
  m.GCID as gcid,
  m.total_deposits AS total_deposits_gbp,
  m.total_withdrawals AS total_withdrawals_gbp,
  m.total_deposits - m.total_withdrawals AS net_flow_gbp,
  m.total_deposits * COALESCE(r.gbp_to_usd_rate, 0) AS total_deposits_usd,
  m.total_withdrawals * COALESCE(r.gbp_to_usd_rate, 0) AS total_withdrawals_usd,
  (m.total_deposits - m.total_withdrawals) * COALESCE(r.gbp_to_usd_rate, 0) AS net_flow_usd,
  m.count_deposits,
  m.count_withdrawals,
  CASE 
    WHEN m.date = f.first_deposit_date AND m.total_deposits > 0 
    THEN TRUE 
    ELSE FALSE 
  END AS is_ftd
FROM mimo_daily m
LEFT JOIN first_deposit_dates f
  ON m.GCID = f.GCID
LEFT JOIN gbp_usd_rates r
  ON m.date = r.rate_date
