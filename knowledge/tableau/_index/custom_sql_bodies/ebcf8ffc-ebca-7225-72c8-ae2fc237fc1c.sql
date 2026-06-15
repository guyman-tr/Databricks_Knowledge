SELECT
'Deposit' as `Transaction Type`,
RealCID as CID,
etr_ymd as transaction_date,
SUM(Amount) AS amount
FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction
WHERE ActionTypeID = 7
AND DateID >>= CAST(to_char(CURRENT_DATE - INTERVAL 6 months, 'yyyyMMdd') AS int)
AND DateID != CAST(to_char(CURRENT_DATE, 'yyyyMMdd') AS int)
GROUP BY RealCID, etr_ymd
UNION
SELECT
'Withdrawal' as `Transaction Type`,
RealCID as CID,
etr_ymd as transaction_date,
SUM(Amount) AS amount
FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction
WHERE ActionTypeID = 8
AND DateID >>= CAST(to_char(CURRENT_DATE - INTERVAL 6 months, 'yyyyMMdd') AS int)
AND DateID != CAST(to_char(CURRENT_DATE, 'yyyyMMdd') AS int)
GROUP BY RealCID, etr_ymd
UNION
SELECT
'Compensation' as `Transaction Type`,
RealCID as CID,
etr_ymd as transaction_date,
SUM(Amount) AS amount
FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction
WHERE ActionTypeID = 36
AND DateID >>= CAST(to_char(CURRENT_DATE - INTERVAL 6 months, 'yyyyMMdd') AS int)
AND DateID != CAST(to_char(CURRENT_DATE, 'yyyyMMdd') AS int)
GROUP BY RealCID, etr_ymd