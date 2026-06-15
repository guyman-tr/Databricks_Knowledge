SELECT a.*
	, dc.Name AS Country
	, dmc.Name AS MifidCategory
	, dpl.Name AS PlayerLevel
	, dr.Name AS Regulation
FROM 
(
SELECT 'Yesterday' AS TimeRange, *
FROM BI_DB_dbo.Function_DDR_Aggregation_Yesterday (cast(getdate()-1 as Date),0) 
UNION ALL 
SELECT 'ThisWeek' AS TimeRange, *
FROM BI_DB_dbo.Function_DDR_Aggregation_ThisWeek (cast(getdate()-1 as Date),0) 
UNION ALL 
SELECT 'ThisMonth' AS TimeRange, *
FROM BI_DB_dbo.Function_DDR_Aggregation_ThisMonth (cast(getdate()-1 as Date),0) 
UNION ALL 
SELECT 'ThisQuarter' AS TimeRange, *
FROM BI_DB_dbo.Function_DDR_Aggregation_ThisQuarter (cast(getdate()-1 as Date),0) 
UNION ALL 
SELECT 'ThisYear' AS TimeRange, *
FROM BI_DB_dbo.Function_DDR_Aggregation_ThisYear  (cast(getdate()-1 as Date),0)
) a
JOIN DWH_dbo.Dim_Country dc
	ON a.CountryID = dc.CountryID
JOIN DWH_dbo.Dim_MifidCategorization dmc
	ON a.MifidCategorizationID = dmc.MifidCategorizationID
JOIN DWH_dbo.Dim_PlayerLevel dpl
	ON a.PlayerLevelID = dpl.PlayerLevelID
JOIN DWH_dbo.Dim_Regulation dr
	ON a.RegulationID = dr.DWHRegulationID