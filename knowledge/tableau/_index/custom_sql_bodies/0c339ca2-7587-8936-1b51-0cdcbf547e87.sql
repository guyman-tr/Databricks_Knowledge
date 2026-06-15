-- Spaceship FTDs by time range — single YTD scan
-- Fixed: no internal_transfer filter (FTDs can be internal, e.g. Money→Voyager)
-- Fixed: COUNT(DISTINCT user_id) not row count
WITH max_date_val AS (
  SELECT MAX(date) AS max_date FROM main.etoro_kpi.v_spaceship_mimo
),
base AS (
  SELECT m.date, m.user_id, mv.max_date,
    DATE_SUB(mv.max_date, 1) AS yesterday,
    DATE_TRUNC('week', DATE_ADD(DATE_SUB(mv.max_date, 1), 1)) - INTERVAL 1 DAY AS week_start
  FROM main.etoro_kpi.v_spaceship_mimo m
  CROSS JOIN max_date_val mv
  WHERE m.is_ftd = TRUE
    AND m.date >= DATE_TRUNC('year', DATE_SUB(mv.max_date, 1))
    AND m.date < mv.max_date
)
SELECT
  COUNT(DISTINCT CASE WHEN date = yesterday                         THEN user_id END) AS ftds_yesterday,
  COUNT(DISTINCT CASE WHEN date >= week_start                       THEN user_id END) AS ftds_this_week,
  COUNT(DISTINCT CASE WHEN date >= DATE_TRUNC('month', yesterday)   THEN user_id END) AS ftds_this_month,
  COUNT(DISTINCT CASE WHEN date >= DATE_TRUNC('quarter', yesterday) THEN user_id END) AS ftds_this_quarter,
  COUNT(DISTINCT user_id)                                                              AS ftds_this_year
FROM base