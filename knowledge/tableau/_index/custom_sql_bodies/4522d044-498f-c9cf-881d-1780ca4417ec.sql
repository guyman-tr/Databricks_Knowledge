SELECT *
,SUM(TotalUSD) OVER (Partition BY CompensationReason ORDER BY EndOfMonth) AS RunningTotal
FROM #12M_Total
WHERE EndOfMonth >= DATEADD(MONTH, -11, GETDATE())