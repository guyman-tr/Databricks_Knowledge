SELECT DateID, 'BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status' AS TableName, count(*) AS CountAll  FROM BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status WHERE DateID BETWEEN CAST(FORMAT(CAST(getdate()-7 AS DATE),'yyyyMMdd') as INT) AND CAST(FORMAT(CAST(GETDATE() AS DATE),'yyyyMMdd') as INT) GROUP BY DateID 
UNION ALL 
SELECT DateID, 'BI_DB_dbo.BI_DB_DDR_Customer_Periodic_Status' AS TableName, count(*) AS CountAll  FROM BI_DB_dbo.BI_DB_DDR_Customer_Periodic_Status WHERE DateID BETWEEN CAST(FORMAT(CAST(getdate()-7 AS DATE),'yyyyMMdd') as INT) AND CAST(FORMAT(CAST(getdate() AS DATE),'yyyyMMdd') as INT) GROUP BY DateID 
UNION ALL
SELECT DateID, 'BI_DB_dbo.BI_DB_DDR_Fact_AUM' AS TableName, count(*) AS CountAll  FROM BI_DB_dbo.BI_DB_DDR_Fact_AUM WHERE DateID BETWEEN CAST(FORMAT(CAST(getdate()-7 AS DATE),'yyyyMMdd') as INT) AND CAST(FORMAT(CAST(getdate() AS DATE),'yyyyMMdd') as INT) GROUP BY DateID 
UNION ALL
SELECT DateID, 'BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms' AS TableName, count(*) AS CountAll  FROM BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms WHERE DateID BETWEEN CAST(FORMAT(CAST(getdate()-7 AS DATE),'yyyyMMdd') as INT) AND CAST(FORMAT(CAST(getdate() AS DATE),'yyyyMMdd') as INT) GROUP BY DateID 
UNION ALL
SELECT DateID, 'BI_DB_dbo.BI_DB_DDR_Fact_MIMO_eMoney_Platform' AS TableName, count(*) AS CountAll  FROM BI_DB_dbo.BI_DB_DDR_Fact_MIMO_eMoney_Platform WHERE DateID BETWEEN CAST(FORMAT(CAST(getdate()-7 AS DATE),'yyyyMMdd') as INT) AND CAST(FORMAT(CAST(getdate() AS DATE),'yyyyMMdd') as INT) GROUP BY DateID 
UNION ALL
SELECT DateID, 'BI_DB_dbo.BI_DB_DDR_Fact_PnL' AS TableName, count(*)  AS CountAll FROM BI_DB_dbo.BI_DB_DDR_Fact_PnL WHERE DateID BETWEEN CAST(FORMAT(CAST(getdate()-7 AS DATE),'yyyyMMdd') as INT) AND CAST(FORMAT(CAST(getdate() AS DATE),'yyyyMMdd') as INT) GROUP BY DateID 
UNION ALL
SELECT DateID, 'BI_DB_dbo.BI_DB_DDR_Fact_Revenue_Generating_Actions' AS TableName, count(*)  AS CountAll FROM BI_DB_dbo.BI_DB_DDR_Fact_Revenue_Generating_Actions WHERE DateID BETWEEN CAST(FORMAT(CAST(getdate()-7 AS DATE),'yyyyMMdd') as INT) AND CAST(FORMAT(CAST(getdate() AS DATE),'yyyyMMdd') as INT) GROUP BY DateID 
UNION ALL
SELECT DateID, 'BI_DB_dbo.BI_DB_DDR_Fact_Trading_Volumes_And_Amounts' AS TableName, count(*) AS CountAll  FROM BI_DB_dbo.BI_DB_DDR_Fact_Trading_Volumes_And_Amounts WHERE DateID BETWEEN CAST(FORMAT(CAST(getdate()-7 AS DATE),'yyyyMMdd') as INT) AND CAST(FORMAT(CAST(getdate() AS DATE),'yyyyMMdd') as INT) GROUP BY DateID 
UNION ALL
SELECT ConversionDateID AS DateID, 'EXW_dbo.EXW_C2F_E2E' AS TableName, count(*) AS CountAll  FROM EXW_dbo.EXW_C2F_E2E WHERE ConversionDateID BETWEEN CAST(FORMAT(CAST(getdate()-7 AS DATE),'yyyyMMdd') as INT) AND CAST(FORMAT(CAST(getdate() AS DATE),'yyyyMMdd') as INT) GROUP BY ConversionDateID