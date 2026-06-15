SELECT 
 efb.FullDate
, SUM(efb.BalanceUSD) 'BalanceUSD'
, COUNT(DISTINCT efb.GCID) Users 
FROM EXW_FactBalance efb WITH (NOLOCK)
JOIN EXW_DimUser edu ON efb.GCID = edu.GCID AND edu.IsTestAccount =0
WHERE efb.GCID >0 
AND efb.FullDateID >=   CAST(CONVERT (VARCHAR(8) , DATEADD(week, -5,CAST(DATEADD(week, DATEDIFF(week, -1, GETDATE()), -1) AS DATE))  , 112 ) AS INT) 
AND (efb.FullDateID  =     CAST(CONVERT(VARCHAR(8), DATEADD(DAY, 7 - DATEPART(WEEKDAY, FullDate), FullDate) , 112) AS INT) 
											OR efb.FullDateID=    CAST(CONVERT(VARCHAR(8), getdate()-1, 112) AS INT) )
GROUP BY efb.FullDate