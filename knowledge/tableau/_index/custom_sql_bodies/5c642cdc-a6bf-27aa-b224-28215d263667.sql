SELECT 'BI_DB_RecurringInvestment_Positions' AS TableName, 'DataLake' AS OriginalSource, max(dp.OpenDateID) AS MaxOpenDateID
FROM BI_DB_dbo.BI_DB_RecurringInvestment_Positions bdrip
JOIN DWH_dbo.Dim_Position dp
	ON bdrip.PositionID = dp.PositionID AND dp.OpenDateID > CAST(FORMAT(CAST(GETDATE()-10 AS DATE),'yyyyMMdd') as INT)
UNION ALL 
SELECT 'BI_DB_Positions_Closed_To_IBAN' AS TableName, 'DataLake' AS OriginalSource, max(dp.OpenDateID) AS MaxOpenDateID
FROM BI_DB_dbo.BI_DB_Positions_Closed_To_IBAN bdrip
JOIN DWH_dbo.Dim_Position dp
	ON bdrip.PositionID = dp.PositionID AND dp.OpenDateID > CAST(FORMAT(CAST(GETDATE()-10 AS DATE),'yyyyMMdd') as INT)
UNION all
SELECT 'BI_DB_Positions_Opened_From_IBAN' AS TableName, 'DataLake' AS OriginalSource, max(dp.OpenDateID) AS MaxOpenDateID
FROM BI_DB_dbo.BI_DB_Positions_Opened_From_IBAN bdrip
JOIN DWH_dbo.Dim_Position dp
	ON bdrip.PositionID = dp.PositionID AND dp.OpenDateID > CAST(FORMAT(CAST(GETDATE()-10 AS DATE),'yyyyMMdd') as INT)
UNION ALL 
SELECT 'BI_DB_CopyFund_Positions' AS TableName,  'Synapse' AS OriginalSource, max(dp.OpenDateID) AS MaxOpenDateID
FROM BI_DB_dbo.BI_DB_CopyFund_Positions bdrip
JOIN DWH_dbo.Dim_Position dp
	ON bdrip.PositionID = dp.PositionID AND dp.OpenDateID > CAST(FORMAT(CAST(GETDATE()-10 AS DATE),'yyyyMMdd') as INT)
UNION ALL 
SELECT 'BI_DB_CopyFund_Positions' AS TableName,  'Synapse' AS OriginalSource, max(dp.OpenDateID) AS MaxOpenDateID
FROM BI_DB_dbo.BI_DB_Fact_Customer_Action_Position_Distribution bdrip
JOIN DWH_dbo.Dim_Position dp
	ON bdrip.PositionID = dp.PositionID AND dp.OpenDateID > CAST(FORMAT(CAST(GETDATE()-10 AS DATE),'yyyyMMdd') as INT)