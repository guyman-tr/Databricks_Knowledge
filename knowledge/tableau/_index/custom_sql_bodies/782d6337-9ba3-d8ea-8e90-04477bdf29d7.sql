SELECT 'FullCommission' AS Metric, a.DateID AS DDRDateID , a.DDRAmount , b.DateID AS DWHDateID, b.FunctionAmount ,  abs(ISNULL(DDRAmount,0) - ISNULL(FunctionAmount,0)) AS Diff
FROM 
(
SELECT bddfrga.DateID, sum(bddfrga.Amount) AS DDRAmount
FROM BI_DB_dbo.BI_DB_DDR_Fact_Revenue_Generating_Actions bddfrga
WHERE bddfrga.DateID >= CAST(FORMAT(CAST(GETDATE()-7 AS DATE),'yyyyMMdd') as INT)
AND bddfrga.Metric = 'FullCommission'
GROUP BY bddfrga.DateID
) a
FULL OUTER JOIN 
(
SELECT DateID, sum(TotalFullCommission)  AS FunctionAmount
FROM BI_DB_dbo.Function_Revenue_FullCommissions(CAST(FORMAT(CAST(getdate()-7 AS DATE),'yyyyMMdd') as INT), CAST(FORMAT(CAST(GETDATE()-1 AS DATE),'yyyyMMdd') as INT),0) 
GROUP BY DateID
) b
ON a.DateID = b.DateID
WHERE ISNULL(a.DDRAmount,0) <> ISNULL(b.FunctionAmount,0)

UNION ALL 

SELECT 'GlobalFtds' AS Metric, a.DateID AS DDRDateID , a.DDRAmount , b.DateID AS DWHDateID, b.FunctionAmount ,  abs(ISNULL(DDRAmount,0) - ISNULL(FunctionAmount,0)) AS Diff
FROM 
(
SELECT bddfrga.DateID, sum(CASE WHEN bddfrga.Global_FTD_DateID = bddfrga.DateID THEN 1 ELSE 0 end) AS DDRAmount
FROM BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status bddfrga
WHERE bddfrga.DateID >= CAST(FORMAT(CAST(getdate()-7 AS DATE),'yyyyMMdd') as INT)
GROUP BY bddfrga.DateID
) a
FULL OUTER JOIN 
(
SELECT CAST(FORMAT(CAST(FirstDepositDate AS DATE),'yyyyMMdd') as INT) AS DateID, count(fca.RealCID) AS FunctionAmount
FROM DWH_dbo.Dim_Customer fca
Where CAST(FirstDepositDate AS DATE) >= getdate()-8
GROUP BY CAST(FORMAT(CAST(FirstDepositDate AS DATE),'yyyyMMdd') as INT)
) b
ON a.DateID = b.DateID