SELECT bdt.* , dc.MarketingRegionManualName
FROM BI_DB_dbo.BI_DB_DailyTaboolaCombineAffwiz bdt
JOIN DWH_dbo.Dim_Country dc ON bdt.Country=dc.Name