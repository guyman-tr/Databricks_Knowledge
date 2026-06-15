-- Spaceship AUM snapshot — latest available, incl. Money
-- Per-product carry-forward (7-day window) + Money running balance
WITH aum_base AS (
  SELECT user_id, date_id,
    super_balance_usd, voyager_balance_usd, nova_balance_usd
  FROM main.etoro_kpi.v_spaceship_aum
  WHERE date_id BETWEEN
    CAST(DATE_FORMAT(DATE_ADD(CURRENT_DATE(), -7), 'yyyyMMdd') AS INT)
    AND CAST(DATE_FORMAT(DATE_ADD(CURRENT_DATE(), -1), 'yyyyMMdd') AS INT)
),
product_dates AS (
  SELECT
    MAX(CASE WHEN super_balance_usd > 0   THEN date_id END) AS super_date,
    MAX(CASE WHEN voyager_balance_usd > 0 THEN date_id END) AS voyager_date,
    MAX(CASE WHEN nova_balance_usd > 0    THEN date_id END) AS nova_date
  FROM aum_base
),
user_balances AS (
  SELECT
    b.user_id,
    MAX(CASE WHEN b.date_id = p.super_date   THEN b.super_balance_usd   END) AS super_bal,
    MAX(CASE WHEN b.date_id = p.voyager_date THEN b.voyager_balance_usd END) AS voyager_bal,
    MAX(CASE WHEN b.date_id = p.nova_date    THEN b.nova_balance_usd    END) AS nova_bal
  FROM aum_base b
  CROSS JOIN product_dates p
  WHERE b.date_id IN (p.super_date, p.voyager_date, p.nova_date)
  GROUP BY b.user_id
),
-- Money running balance → USD (dashboard pattern)
contact_mapping AS (
  SELECT DISTINCT account_id, user_id
  FROM main.spaceship.bronze_spaceship_metabase_contact
  WHERE account_id IS NOT NULL AND user_id IS NOT NULL
),
money_daily AS (
  SELECT CAST(FROM_UTC_TIMESTAMP(mt.completed_at, 'Australia/Sydney') AS DATE) AS date,
    cm.user_id,
    SUM(CASE WHEN mt.transaction_direction = 'CREDIT' THEN CAST(mt.aud_amount AS DOUBLE)
             ELSE -ABS(CAST(mt.aud_amount AS DOUBLE)) END) AS daily_net
  FROM main.spaceship.bronze_spaceship_analytics_fct_money_transactions mt
  JOIN contact_mapping cm ON mt.account_id = cm.account_id
  WHERE mt.is_completed = true AND mt.is_reversed = false
  GROUP BY 1, 2
),
money_latest_aud AS (
  SELECT user_id,
    SUM(daily_net) AS money_bal_aud
  FROM money_daily
  GROUP BY user_id
),
-- AUD→USD rate (latest available, mid-market)
aud_usd AS (
  SELECT (Ask + Bid) / 2 AS rate
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit
  WHERE InstrumentID = 7
  ORDER BY Occurred DESC
  LIMIT 1
),
money_latest AS (
  SELECT m.user_id,
    m.money_bal_aud,
    m.money_bal_aud * r.rate AS money_bal_usd
  FROM money_latest_aud m
  CROSS JOIN aud_usd r
),
-- Combine AUM + Money
combined AS (
  SELECT
    COALESCE(a.user_id, m.user_id) AS user_id,
    COALESCE(a.super_bal, 0)     AS super_bal,
    COALESCE(a.voyager_bal, 0)   AS voyager_bal,
    COALESCE(a.nova_bal, 0)      AS nova_bal,
    COALESCE(m.money_bal_usd, 0) AS money_bal
  FROM user_balances a
  FULL OUTER JOIN money_latest m ON a.user_id = m.user_id
),
tagged AS (
  SELECT *,
    super_bal + voyager_bal + nova_bal + money_bal > 0 AS is_funded
  FROM combined
)
SELECT
  'Latest Available'              AS TimeRange,
  t.is_funded,
  p.super_date,
  p.voyager_date,
  p.nova_date,
  SUM(t.super_bal)                AS Super,
  SUM(t.voyager_bal)              AS Voyager,
  SUM(t.nova_bal)                 AS Nova,
  SUM(t.money_bal)                AS Money,                                -- added
  SUM(t.super_bal + t.voyager_bal + t.nova_bal + t.money_bal) AS Total
FROM tagged t
CROSS JOIN product_dates p
GROUP BY t.is_funded, p.super_date, p.voyager_date, p.nova_date