SELECT a.*
       ,LAG(CASE WHEN a.Churn=1 THEN 1 ELSE 0 END,1) OVER (PARTITION BY a.RealCID ORDER BY a.RealCID, a.Active_Month ASC) AS Previous_Churn_Lag1
       ,CASE WHEN (LAG(CASE WHEN a.Churn=1 THEN 1 ELSE 0 END,1) OVER (PARTITION BY a.RealCID ORDER BY a.RealCID, a.Active_Month ASC)+a.Win_Back)=2 THEN 1 ELSE 0 END AS AO_Winback_from_Previous_month
FROM BI_DB_dbo.BI_DB_Crypto_Active_Open_Churn_Winback a