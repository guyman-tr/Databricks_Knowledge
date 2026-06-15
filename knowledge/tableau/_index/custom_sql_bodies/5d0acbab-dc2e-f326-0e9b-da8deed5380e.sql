SELECT 
 dc1.MarketingRegionManualName Region,
month(dp.OpenOccurred) + year(dp.OpenOccurred) *100 ActiveMonth,
   count ( DISTINCT dp.CID) users
FROM DWH_dbo.Dim_Position dp
JOIN DWH_dbo.Dim_Instrument  di ON dp.InstrumentID = di.InstrumentID
JOIN DWH_dbo.Dim_Customer  dc ON dc.RealCID=dp.CID AND dc.IsValidCustomer=1
JOIN DWH_dbo.Dim_Country  dc1 ON dc.CountryID = dc1.CountryID 
WHERE CAST(dp.OpenOccurred AS DATE) >= '2024-10-01'
AND ISNULL(dp.IsAirDrop, 0 )=0 
AND ISNULL(dp.IsPartialCloseChild, 0) = 0
GROUP BY 
MarketingRegionManualName,
month(dp.OpenOccurred) + year(dp.OpenOccurred) *100