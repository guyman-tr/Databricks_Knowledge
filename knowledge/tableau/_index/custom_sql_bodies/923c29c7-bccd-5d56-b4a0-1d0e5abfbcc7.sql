WITH max_date_val AS (
    -- אנחנו מגדירים את "היום" כיום המקסימלי בטבלה
    SELECT MAX(date) AS max_date FROM main.etoro_kpi_prep.v_spaceship_mimo
),
base_data AS (
    SELECT 
        date,
        is_ftd,
        product,
        total_deposits_usd,
        total_withdrawals_usd,
        net_flow_usd
    FROM main.etoro_kpi_prep.v_spaceship_mimo
    WHERE is_internal_transfer = 'false'
)
-- אתמול
SELECT 'Yesterday' AS TimeRange, is_ftd, product,
    SUM(total_deposits_usd) AS Total_Deposits,
    SUM(total_withdrawals_usd) AS Total_Withdrawals,
    SUM(net_flow_usd) AS Net_Flow
FROM base_data, max_date_val
WHERE date = DATE_SUB(max_date, 1)
GROUP BY 1, 2, 3

UNION ALL
-- השבוע (מתואם להתחלה ביום ראשון כדי שיהיה זהה לאתמול אם היום יום שני)
SELECT 'This Week' AS TimeRange, is_ftd, product,
    SUM(total_deposits_usd), SUM(total_withdrawals_usd), SUM(net_flow_usd)
FROM base_data, max_date_val
WHERE date >= DATE_TRUNC('week', DATE_ADD(DATE_SUB(max_date, 1), 1)) - INTERVAL 1 DAY
  AND date < max_date
GROUP BY 1, 2, 3

UNION ALL
SELECT 'This Month' AS TimeRange, is_ftd, product,
    SUM(total_deposits_usd), SUM(total_withdrawals_usd), SUM(net_flow_usd)
FROM base_data, max_date_val
WHERE date >= DATE_TRUNC('month', DATE_SUB(max_date, 1))
  AND date < max_date
GROUP BY 1, 2, 3

UNION ALL
SELECT 'This Quarter' AS TimeRange, is_ftd, product,
    SUM(total_deposits_usd), SUM(total_withdrawals_usd), SUM(net_flow_usd)
FROM base_data, max_date_val
WHERE date >= DATE_TRUNC('quarter', DATE_SUB(max_date, 1))
  AND date < max_date
GROUP BY 1, 2, 3

UNION ALL
SELECT 'This Year' AS TimeRange, is_ftd, product,
    SUM(total_deposits_usd), SUM(total_withdrawals_usd), SUM(net_flow_usd)
FROM base_data, max_date_val
WHERE date >= DATE_TRUNC('year', DATE_SUB(max_date, 1))
  AND date < max_date
GROUP BY 1, 2, 3