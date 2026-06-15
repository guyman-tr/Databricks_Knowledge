SELECT 
    DATE(ca.Occurred) as LoginDate,
    COUNT(DISTINCT ca.gcid) as Daily_Login_Count
FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ca
WHERE ca.ActionTypeID = 14 
  AND ca.Occurred >= '2024-01-01'
GROUP BY 1