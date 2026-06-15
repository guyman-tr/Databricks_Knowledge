-- Spaceship Fees by time range — single YTD scan, reshaped for Tableau
WITH max_date_val AS (
  SELECT MAX(date) AS max_date FROM main.etoro_kpi.v_spaceship_fees
),
base AS (
  SELECT f.date, f.product, f.total_fees_usd, m.max_date,
    -- Week starts Sunday: on Monday, This Week = just Sunday = Yesterday
    DATE_TRUNC('week', DATE_ADD(m.max_date, 1)) - INTERVAL 1 DAY AS week_start
  FROM main.etoro_kpi.v_spaceship_fees f
  CROSS JOIN max_date_val m
  WHERE f.date >= DATE_TRUNC('year', m.max_date)
),
agg AS (
  SELECT
    product,
    SUM(CASE WHEN date = max_date                          THEN total_fees_usd ELSE 0 END) AS yesterday_val,
    SUM(CASE WHEN date >= week_start                       THEN total_fees_usd ELSE 0 END) AS week_val,
    SUM(CASE WHEN date >= DATE_TRUNC('month', max_date)    THEN total_fees_usd ELSE 0 END) AS month_val,
    SUM(CASE WHEN date >= DATE_TRUNC('quarter', max_date)  THEN total_fees_usd ELSE 0 END) AS quarter_val,
    SUM(total_fees_usd)                                                                     AS year_val
  FROM base
  GROUP BY product
)
SELECT 'Yesterday'    AS TimeRange, product, yesterday_val AS Value FROM agg
UNION ALL
SELECT 'This Week',    product, week_val    FROM agg
UNION ALL
SELECT 'This Month',   product, month_val   FROM agg
UNION ALL
SELECT 'This Quarter', product, quarter_val FROM agg
UNION ALL
SELECT 'This Year',    product, year_val    FROM agg