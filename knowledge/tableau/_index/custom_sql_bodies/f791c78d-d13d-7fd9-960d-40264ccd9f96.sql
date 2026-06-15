-- Spaceship MIMO by time range — single YTD scan, reshaped for Tableau
-- max_date = "today" (may be partial), so we use max_date - 1 as yesterday
WITH max_date_val AS (
  SELECT MAX(date) AS max_date FROM main.etoro_kpi.v_spaceship_mimo
),
base AS (
  SELECT
    m.date, m.is_ftd, m.product,
    m.total_deposits_usd, m.total_withdrawals_usd, m.net_flow_usd,
    mv.max_date,
    DATE_SUB(mv.max_date, 1) AS yesterday,
    -- Week starts Sunday: on Monday, This Week = just Sunday = Yesterday
    DATE_TRUNC('week', DATE_ADD(DATE_SUB(mv.max_date, 1), 1)) - INTERVAL 1 DAY AS week_start
  FROM main.etoro_kpi.v_spaceship_mimo m
  CROSS JOIN max_date_val mv
  WHERE m.is_internal_transfer = FALSE                       -- fixed: boolean not string
    AND m.date >= DATE_TRUNC('year', DATE_SUB(mv.max_date, 1))
    AND m.date < mv.max_date                                 -- exclude "today" (partial)
),
agg AS (
  SELECT
    is_ftd, product,
    SUM(CASE WHEN date = yesterday                            THEN total_deposits_usd    ELSE 0 END) AS dep_yesterday,
    SUM(CASE WHEN date = yesterday                            THEN total_withdrawals_usd ELSE 0 END) AS wdr_yesterday,
    SUM(CASE WHEN date = yesterday                            THEN net_flow_usd          ELSE 0 END) AS net_yesterday,
    SUM(CASE WHEN date >= week_start                          THEN total_deposits_usd    ELSE 0 END) AS dep_week,
    SUM(CASE WHEN date >= week_start                          THEN total_withdrawals_usd ELSE 0 END) AS wdr_week,
    SUM(CASE WHEN date >= week_start                          THEN net_flow_usd          ELSE 0 END) AS net_week,
    SUM(CASE WHEN date >= DATE_TRUNC('month', yesterday)      THEN total_deposits_usd    ELSE 0 END) AS dep_month,
    SUM(CASE WHEN date >= DATE_TRUNC('month', yesterday)      THEN total_withdrawals_usd ELSE 0 END) AS wdr_month,
    SUM(CASE WHEN date >= DATE_TRUNC('month', yesterday)      THEN net_flow_usd          ELSE 0 END) AS net_month,
    SUM(CASE WHEN date >= DATE_TRUNC('quarter', yesterday)    THEN total_deposits_usd    ELSE 0 END) AS dep_quarter,
    SUM(CASE WHEN date >= DATE_TRUNC('quarter', yesterday)    THEN total_withdrawals_usd ELSE 0 END) AS wdr_quarter,
    SUM(CASE WHEN date >= DATE_TRUNC('quarter', yesterday)    THEN net_flow_usd          ELSE 0 END) AS net_quarter,
    SUM(total_deposits_usd)                                                                           AS dep_year,
    SUM(total_withdrawals_usd)                                                                        AS wdr_year,
    SUM(net_flow_usd)                                                                                 AS net_year
  FROM base
  GROUP BY is_ftd, product
)
SELECT 'Yesterday'    AS TimeRange, is_ftd, product, dep_yesterday AS Total_Deposits, wdr_yesterday AS Total_Withdrawals, net_yesterday AS Net_Flow FROM agg
UNION ALL
SELECT 'This Week',    is_ftd, product, dep_week,    wdr_week,    net_week    FROM agg
UNION ALL
SELECT 'This Month',   is_ftd, product, dep_month,   wdr_month,   net_month   FROM agg
UNION ALL
SELECT 'This Quarter', is_ftd, product, dep_quarter,  wdr_quarter, net_quarter FROM agg
UNION ALL
SELECT 'This Year',    is_ftd, product, dep_year,     wdr_year,    net_year    FROM agg