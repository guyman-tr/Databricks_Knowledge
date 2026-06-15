SELECT dc1.MarketingRegionManualName Region
FROM [DWH_dbo].[Dim_Country] dc1 WITH (NOLOCK)
GROUP by dc1.MarketingRegionManualName