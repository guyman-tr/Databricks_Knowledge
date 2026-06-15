SELECT
ddr.*
,dcn.[Name] AS Country
,dmc.[Name] AS MifidCategory
,dpl.[Name] AS PlayerLevel
,reg.[Name] AS Regulation
FROM(
SELECT 'Yesterday' AS TimeRange, *
FROM BI_DB_dbo.Function_DDR_Aggregation_Yesterday (CAST(GETDATE()-1 AS Date),0) 
UNION ALL 
SELECT 'ThisWeek' AS TimeRange, *
FROM BI_DB_dbo.Function_DDR_Aggregation_ThisWeek (CAST(GETDATE()-1 AS Date),0) 
UNION ALL 
SELECT 'ThisMonth' AS TimeRange, *
FROM BI_DB_dbo.Function_DDR_Aggregation_ThisMonth (CAST(GETDATE()-1 AS Date),0) 
UNION ALL 
SELECT 'ThisQuarter' AS TimeRange, *
FROM BI_DB_dbo.Function_DDR_Aggregation_ThisQuarter (CAST(GETDATE()-1 AS Date),0) 
UNION ALL
SELECT 'ThisYear' AS TimeRange, *
FROM BI_DB_dbo.Function_DDR_Aggregation_ThisYear (CAST(GETDATE()-1 AS Date),0)
) ddr
INNER JOIN DWH_dbo.Dim_Country dcn             ON ddr.CountryID = dcn.CountryID
INNER JOIN DWH_dbo.Dim_MifidCategorization dmc ON ddr.MifidCategorizationID = dmc.MifidCategorizationID
INNER JOIN DWH_dbo.Dim_PlayerLevel dpl         ON ddr.PlayerLevelID = dpl.PlayerLevelID
INNER JOIN DWH_dbo.Dim_Regulation reg          ON ddr.RegulationID = reg.DWHRegulationID