SELECT a.DateID
	, 'BI_DB_DDR_Fact_PnL' AS TableName
	, 'Compare to FCA netprofit' AS Test
	, a.SourceMetric
	, b.NewDDRMetric
	, a.SourceMetric - b.NewDDRMetric AS MetricDiff
from 
(
SELECT so.DateID
	,  sum(so.NetProfit) AS SourceMetric
FROM DWH_dbo.Fact_CustomerAction so
WHERE  so.DateID >=  CAST(FORMAT(CAST(dateadd(WEEK,-1,GETDATE()-1) AS DATE),'yyyyMMdd') as INT)
AND so.ActionTypeID IN (4,5,6,28,40)
GROUP BY so.DateID
)a
LEFT JOIN 
(
SELECT ddr.DateID
	, sum ( ddr.NetProfit) AS NewDDRMetric
FROM BI_DB_dbo.BI_DB_DDR_Fact_PnL ddr
WHERE ddr.DateID >= CAST(FORMAT(CAST(dateadd(WEEK,-1,GETDATE()-1) AS DATE),'yyyyMMdd') as INT)
GROUP BY ddr.DateID
) b
ON a.DateID = b.DateID
--ORDER BY a.DateID

UNION ALL

SELECT a.DateID
	, 'BI_DB_DDR_Fact_Non_Revenue_Generating_Actions' AS TableName
	, 'Compare to FCA new copy' AS Test
	, a.SourceMetric
	, b.NewDDRMetric
	, a.SourceMetric - b.NewDDRMetric AS MetricDiff
from 
(
SELECT so.DateID
	, -1 * sum(so.Amount) AS SourceMetric
FROM DWH_dbo.Fact_CustomerAction so
WHERE  so.DateID >=  CAST(FORMAT(CAST(dateadd(WEEK,-1,GETDATE()-1) AS DATE),'yyyyMMdd') as INT)
AND so.ActionTypeID = 17
GROUP BY so.DateID
)a
LEFT JOIN 
(
SELECT ddr.DateID
	, sum ( ddr.Amount) AS NewDDRMetric
FROM BI_DB_dbo.BI_DB_DDR_Fact_Non_Revenue_Generating_Actions ddr
WHERE ddr.DateID >=  CAST(FORMAT(CAST(dateadd(WEEK,-1,GETDATE()-1) AS DATE),'yyyyMMdd') as INT)
AND ddr.ActionType = 'NewCopy'
GROUP BY ddr.DateID
) b
ON a.DateID = b.DateID
--ORDER BY a.DateID

UNION ALL



SELECT a.DateID
	, 'BI_DB_DDR_Customer_Daily_Status' AS TableName
	, 'Compare to dimcustomer ftds' AS Test
	, a.SourceMetric
	, b.NewDDRMetric
	, a.SourceMetric - b.NewDDRMetric AS MetricDiff
from 
(
SELECT CAST(FORMAT(CAST(so.FirstDepositDate AS DATE),'yyyyMMdd') as INT)  AS DateID
	,  count(so.RealCID) AS SourceMetric
FROM DWH_dbo.Dim_Customer  so
WHERE  so.FirstDepositDate BETWEEN cast(GETDATE()-8 AS Date) AND cast(GETDATE() AS date)
GROUP BY CAST(FORMAT(CAST(so.FirstDepositDate AS DATE),'yyyyMMdd') as INT)
) a
LEFT JOIN 
(
SELECT ddr.DateID
	, sum (ddr.GlobalFirstDeposited ) AS NewDDRMetric
FROM BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status ddr
WHERE ddr.DateID >=  CAST(FORMAT(CAST(dateadd(WEEK,-1,GETDATE()-1) AS DATE),'yyyyMMdd') as INT)
GROUP BY ddr.DateID
) b
ON a.DateID = b.DateID
--ORDER BY a.DateID


UNION ALL


SELECT a.DateID
	, 'BI_DB_DDR_Fact_Revenue_Generating_Actions' AS TableName
	, 'Compare to FCA fullcomm' AS Test
	, a.SourceMetric
	, b.NewDDRMetric
	, a.SourceMetric - b.NewDDRMetric AS MetricDiff
from 
(
SELECT so.DateID
	, sum(so.TotalFullCommission) AS SourceMetric
FROM BI_DB_dbo.Function_Revenue_FullCommissions(CAST(FORMAT(CAST(dateadd(WEEK,-1,GETDATE()-1) AS DATE),'yyyyMMdd') as INT),  CAST(FORMAT(CAST(getdate() AS DATE),'yyyyMMdd') as INT),0) so
--WHERE  so.DateID BETWEEN 20250325 AND
--AND so.ActionTypeID = 7
GROUP BY so.DateID
)a
LEFT JOIN 
(
SELECT ddr.DateID
	, sum (ddr.Amount) AS NewDDRMetric
FROM BI_DB_dbo.BI_DB_DDR_Fact_Revenue_Generating_Actions ddr
WHERE ddr.DateID >=  CAST(FORMAT(CAST(dateadd(WEEK,-1,GETDATE()-1) AS DATE),'yyyyMMdd') as INT)
AND Metric = 'FullCommission'
GROUP BY ddr.DateID
) b
ON a.DateID = b.DateID
--ORDER BY a.DateID

UNION ALL


SELECT a.DateID
	, 'BI_DB_DDR_Fact_MIMO_AllPlatforms' AS TableName
	, 'Compare to FCA deposits' AS Test
	, a.SourceMetric
	, b.NewDDRMetric
	, a.SourceMetric - b.NewDDRMetric AS MetricDiff
from 
(
SELECT so.DateID
	, sum(so.Amount) AS SourceMetric
FROM DWH_dbo.Fact_CustomerAction so
WHERE  so.DateID >=  CAST(FORMAT(CAST(dateadd(WEEK,-1,GETDATE()-1) AS DATE),'yyyyMMdd') as INT)
AND so.ActionTypeID IN (7,44)
GROUP BY so.DateID
)a
LEFT JOIN 
(
SELECT ddr.DateID
	, sum (ddr.AmountUSD) AS NewDDRMetric
FROM BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms ddr
WHERE ddr.DateID >=  CAST(FORMAT(CAST(dateadd(WEEK,-1,GETDATE()-1) AS DATE),'yyyyMMdd') as INT)
AND ddr.MIMOAction = 'Deposit'
AND ddr.MIMOPlatform = 'TradingPlatform'
GROUP BY ddr.DateID
) b
ON a.DateID = b.DateID
--ORDER BY a.DateID

UNION ALL


SELECT a.DateID
	, 'BI_DB_DDR_Fact_MIMO_Trading_Platform' AS TableName
	, 'Compare to FCA deposits' AS Test
	, a.SourceMetric
	, b.NewDDRMetric
	, a.SourceMetric - b.NewDDRMetric AS MetricDiff
from 
(
SELECT so.DateID
	, sum(so.Amount) AS SourceMetric
FROM DWH_dbo.Fact_CustomerAction so
WHERE  so.DateID >=  CAST(FORMAT(CAST(dateadd(WEEK,-1,GETDATE()-1) AS DATE),'yyyyMMdd') as INT)
AND so.ActionTypeID IN (7,44)
GROUP BY so.DateID
)a
LEFT JOIN 
(
SELECT ddr.DateID
	, sum (ddr.AmountUSD) AS NewDDRMetric
FROM BI_DB_dbo.BI_DB_DDR_Fact_MIMO_Trading_Platform ddr
WHERE ddr.DateID >=  CAST(FORMAT(CAST(dateadd(WEEK,-1,GETDATE()-1) AS DATE),'yyyyMMdd') as INT)
AND ddr.MIMOAction = 'Deposit'
GROUP BY ddr.DateID
) b
ON a.DateID = b.DateID
--ORDER BY a.DateID

UNION ALL

SELECT a.DateID
	, 'BI_DB_DDR_Fact_AUM' AS TableName
	, 'Compare to Vliabilities' AS Test
	, a.SourceMetric
	, b.NewDDRMetric
	, a.SourceMetric - b.NewDDRMetric AS MetricDiff
from 
(
SELECT vl.DateID
	, sum(vl.NOP) AS SourceMetric
FROM DWH_dbo.V_Liabilities vl
WHERE  vl.DateID >=  CAST(FORMAT(CAST(dateadd(WEEK,-1,GETDATE()-1) AS DATE),'yyyyMMdd') as INT)
GROUP BY vl.DateID
)a
LEFT JOIN 
(
SELECT bddfa.DateID
	, sum (bddfa.NOP) AS NewDDRMetric
FROM BI_DB_dbo.BI_DB_DDR_Fact_AUM bddfa
WHERE bddfa.DateID >=  CAST(FORMAT(CAST(dateadd(WEEK,-1,GETDATE()-1) AS DATE),'yyyyMMdd') as INT)
GROUP BY bddfa.DateID
) b
ON a.DateID = b.DateID
--ORDER BY a.DateID

UNION ALL


SELECT a.DateID
	, 'BI_DB_DDR_Fact_Revenue_Generating_Actions' AS TableName
	, 'Compare to FCA TicketFee' AS Test
	, a.SourceMetric
	, b.NewDDRMetric
	, a.SourceMetric - b.NewDDRMetric AS MetricDiff
from 
(
SELECT so.DateID
	, sum(-1 * so.Amount) AS SourceMetric
FROM DWH_dbo.Fact_CustomerAction so 
WHERE  so.DateID >=  CAST(FORMAT(CAST(dateadd(WEEK,-1,GETDATE()-1) AS DATE),'yyyyMMdd') as INT)
AND so.ActionTypeID = 35
AND IsFeeDividend = 4
GROUP BY so.DateID
)a
LEFT JOIN 
(
SELECT ddr.DateID
	, sum (ddr.Amount) AS NewDDRMetric
FROM BI_DB_dbo.BI_DB_DDR_Fact_Revenue_Generating_Actions ddr
WHERE ddr.DateID >=  CAST(FORMAT(CAST(dateadd(WEEK,-1,GETDATE()-1) AS DATE),'yyyyMMdd') as INT)
AND Metric LIKE '%Tick%'
GROUP BY ddr.DateID
) b
ON a.DateID = b.DateID
--ORDER BY a.DateID