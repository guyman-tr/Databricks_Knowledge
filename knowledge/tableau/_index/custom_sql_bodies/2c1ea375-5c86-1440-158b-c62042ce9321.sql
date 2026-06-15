SELECT [Dim_Country].[CountryID] AS [CountryID],
  [Dim_Country].[MarketingRegionManualName] AS [MarketingRegionManualName],
  [Dim_Country].[Name] AS [Name]
FROM [DWH_dbo].[Dim_Country]  
union all
select top 1 -1 AS [CountryID],
  'All' AS [MarketingRegionManualName],
  'All' AS [Name]
from [DWH_dbo].[Dim_Country]