-- Spaceship Funded Accounts — latest available, incl. Money
-- Per-product carry-forward (7-day window) + Money running balance
WITH aum_base AS (
  SELECT user_id, date_id,
    super_balance_aud, voyager_balance_aud, nova_balance_aud
  FROM main.etoro_kpi.v_spaceship_aum
  WHERE date_id BETWEEN
    CAST(DATE_FORMAT(DATE_ADD(CURRENT_DATE(), -7), 'yyyyMMdd') AS INT)
    AND CAST(DATE_FORMAT(DATE_ADD(CURRENT_DATE(), -1), 'yyyyMMdd') AS INT)
),
product_dates AS (
  SELECT
    MAX(CASE WHEN super_balance_aud > 0   THEN date_id END) AS super_date,
    MAX(CASE WHEN voyager_balance_aud > 0 THEN date_id END) AS voyager_date,
    MAX(CASE WHEN nova_balance_aud > 0    THEN date_id END) AS nova_date
  FROM aum_base
),
user_balances AS (
  SELECT
    b.user_id,
    MAX(CASE WHEN b.date_id = p.super_date   THEN b.super_balance_aud   END) AS super_bal,
    MAX(CASE WHEN b.date_id = p.voyager_date THEN b.voyager_balance_aud END) AS voyager_bal,
    MAX(CASE WHEN b.date_id = p.nova_date    THEN b.nova_balance_aud    END) AS nova_bal
  FROM aum_base b
  CROSS JOIN product_dates p
  WHERE b.date_id IN (p.super_date, p.voyager_date, p.nova_date)
  GROUP BY b.user_id
),
-- Money running balance (dashboard pattern)
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
money_latest AS (
  SELECT user_id,
    SUM(daily_net) AS money_bal
  FROM money_daily
  GROUP BY user_id
),
-- Combine AUM + Money
combined AS (
  SELECT
    COALESCE(a.user_id, m.user_id) AS user_id,
    COALESCE(a.super_bal, 0)   AS super_bal,
    COALESCE(a.voyager_bal, 0) AS voyager_bal,
    COALESCE(a.nova_bal, 0)    AS nova_bal,
    COALESCE(m.money_bal, 0)   AS money_bal
  FROM user_balances a
  FULL OUTER JOIN money_latest m ON a.user_id = m.user_id
)
SELECT
  COUNT(DISTINCT CASE WHEN super_bal + voyager_bal + nova_bal + money_bal > 0 THEN user_id END) AS total_funded_users,
  COUNT(DISTINCT CASE WHEN super_bal > 0   THEN user_id END) AS funded_super,
  COUNT(DISTINCT CASE WHEN voyager_bal > 0 THEN user_id END) AS funded_voyager,
  COUNT(DISTINCT CASE WHEN nova_bal > 0    THEN user_id END) AS funded_nova,
  COUNT(DISTINCT CASE WHEN money_bal > 0   THEN user_id END) AS funded_money,
  p.super_date,
  p.voyager_date,
  p.nova_date
FROM combined
CROSS JOIN product_dates p
GROUP BY p.super_date, p.voyager_date, p.nova_date