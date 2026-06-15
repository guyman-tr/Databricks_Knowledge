SELECT TableName, DateKey as DateID
FROM 
(
SELECT 'BI_DB_DDR_Fact_AUM' AS TableName, DateKey
FROM DWH_dbo.Dim_Date dd
	LEFT JOIN (SELECT DISTINCT DateID FROM BI_DB_dbo.BI_DB_DDR_Fact_AUM) ddr 
		ON dd.DateKey = ddr.DateID
WHERE ddr.DateID IS NULL
AND DateKey > 20150101
AND dd.DateKey <= (SELECT max(DateID) FROM BI_DB_dbo.BI_DB_Client_Balance_Aggregate_Level_New bdcbaln)

UNION ALL 

SELECT 'BI_DB_DDR_Fact_MIMO_Trading_Platform' AS TableName, DateKey
FROM DWH_dbo.Dim_Date dd
	LEFT JOIN (SELECT DISTINCT DateID FROM BI_DB_dbo.BI_DB_DDR_Fact_MIMO_Trading_Platform) ddr 
		ON dd.DateKey = ddr.DateID
WHERE ddr.DateID IS NULL
AND DateKey > 20150101
AND dd.DateKey <= (SELECT max(DateID) FROM BI_DB_dbo.BI_DB_Client_Balance_Aggregate_Level_New bdcbaln)

UNION ALL 

SELECT 'BI_DB_DDR_Fact_MIMO_Trading_Platform' AS TableName, DateKey
FROM DWH_dbo.Dim_Date dd
	LEFT JOIN (SELECT DISTINCT DateID FROM BI_DB_dbo.BI_DB_DDR_Fact_MIMO_eMoney_Platform) ddr -- select min(DateID) from BI_DB_dbo.BI_DB_DDR_Fact_MIMO_eMoney_Platform
		ON dd.DateKey = ddr.DateID
WHERE ddr.DateID IS NULL
AND DateKey > 20201226
AND dd.DateKey <= (SELECT max(DateID) FROM BI_DB_dbo.BI_DB_Client_Balance_Aggregate_Level_New bdcbaln)

UNION ALL 

SELECT 'BI_DB_DDR_Fact_MIMO_All_Platforms' AS TableName, DateKey
FROM DWH_dbo.Dim_Date dd
	LEFT JOIN (SELECT DISTINCT DateID FROM BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms) ddr 
		ON dd.DateKey = ddr.DateID
WHERE ddr.DateID IS NULL
AND DateKey > 20150101
AND dd.DateKey <= (SELECT max(DateID) FROM BI_DB_dbo.BI_DB_Client_Balance_Aggregate_Level_New bdcbaln)

UNION ALL 
/*
SELECT * FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_NAME LIKE '%DDR_Fact%'
*/
SELECT 'BI_DB_DDR_Fact_Non_Revenue_Generating_Actions' AS TableName, DateKey
FROM DWH_dbo.Dim_Date dd
	LEFT JOIN (SELECT DISTINCT DateID FROM BI_DB_dbo.BI_DB_DDR_Fact_Non_Revenue_Generating_Actions) ddr 
		ON dd.DateKey = ddr.DateID
WHERE ddr.DateID IS NULL
AND DateKey > 20150101
AND dd.DateKey <= (SELECT max(DateID) FROM BI_DB_dbo.BI_DB_Client_Balance_Aggregate_Level_New bdcbaln)

UNION ALL 
/*
SELECT * FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_NAME LIKE '%DDR_Fact%'
*/
SELECT 'BI_DB_DDR_Fact_PnL' AS TableName, DateKey
FROM DWH_dbo.Dim_Date dd
	LEFT JOIN (SELECT DISTINCT DateID FROM BI_DB_dbo.BI_DB_DDR_Fact_PnL) ddr 
		ON dd.DateKey = ddr.DateID
WHERE ddr.DateID IS NULL
AND DateKey > 20150101
AND dd.DateKey <= (SELECT max(DateID) FROM BI_DB_dbo.BI_DB_Client_Balance_Aggregate_Level_New bdcbaln)

UNION ALL 
/*
SELECT * FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_NAME LIKE '%DDR_Fact%'
*/
SELECT 'BI_DB_DDR_Fact_Revenue_Generating_Actions' AS TableName, DateKey
FROM DWH_dbo.Dim_Date dd
	LEFT JOIN (SELECT DISTINCT DateID FROM BI_DB_dbo.BI_DB_DDR_Fact_Revenue_Generating_Actions) ddr 
		ON dd.DateKey = ddr.DateID
WHERE ddr.DateID IS NULL
AND DateKey > 20170102
AND dd.DateKey <= (SELECT max(DateID) FROM BI_DB_dbo.BI_DB_Client_Balance_Aggregate_Level_New bdcbaln)

UNION ALL 
/*
SELECT * FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_NAME LIKE '%DDR_Fact%'
*/
SELECT 'BI_DB_DDR_Fact_Trading_Volumes_And_Amounts' AS TableName, DateKey
FROM DWH_dbo.Dim_Date dd
	LEFT JOIN (SELECT DISTINCT DateID FROM BI_DB_dbo.BI_DB_DDR_Fact_Trading_Volumes_And_Amounts) ddr 
		ON dd.DateKey = ddr.DateID
WHERE ddr.DateID IS NULL
AND DateKey > 20170423
AND dd.DateKey <= (SELECT max(DateID) FROM BI_DB_dbo.BI_DB_Client_Balance_Aggregate_Level_New bdcbaln)

UNION ALL 

SELECT 'BI_DB_DDR_Customer_Daily_Status' AS TableName, DateKey
FROM DWH_dbo.Dim_Date dd
	LEFT JOIN (SELECT DISTINCT DateID FROM BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) ddr 
		ON dd.DateKey = ddr.DateID
WHERE ddr.DateID IS NULL
AND DateKey > 20150101
AND dd.DateKey <= (SELECT max(DateID) FROM BI_DB_dbo.BI_DB_Client_Balance_Aggregate_Level_New bdcbaln)

UNION ALL 

SELECT 'BI_DB_DDR_Customer_Periodic_Status' AS TableName, DateKey
FROM DWH_dbo.Dim_Date dd
	LEFT JOIN (SELECT DISTINCT DateID FROM BI_DB_dbo.BI_DB_DDR_Customer_Periodic_Status) ddr 
		ON dd.DateKey = ddr.DateID
WHERE ddr.DateID IS NULL
AND DateKey > 20150101
AND dd.DateKey <= (SELECT max(DateID) FROM BI_DB_dbo.BI_DB_Client_Balance_Aggregate_Level_New bdcbaln)
) a