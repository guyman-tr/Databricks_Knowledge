SELECT df.FTDPlatformName,
fc.FundingType, 
(DATEPART(WEEKDAY, CAST(dc.FirstDepositDate AS DATE)) + @@DATEFIRST - 1) % 7 + 1 AS WeekdayNum, 
CAST(dc.FirstDepositDate AS DATE) AS Date_,
CAST(DATEADD(WEEK, DATEDIFF(WEEK, -1, dc.FirstDepositDate), -1) AS DATE) AS Week_, 
frst.NewMarketingRegion AS Region, 
frst.Country, 
COUNT(*) AS FTDs

FROM DWH_dbo.Dim_Customer dc
JOIN BI_DB_dbo.BI_DB_CIDFirstDates as frst on frst.CID = dc.RealCID
INNER JOIN DWH_dbo.Dim_FTDPlatform df ON dc.FTDPlatformID = df.FTDPlatformID
INNER JOIN DWH_dbo.Dim_Country dc1 ON dc.CountryID = dc1.CountryID 
LEFT JOIN #FTD1 fc ON dc.RealCID=fc.CID
WHERE CAST(dc.FirstDepositDate AS DATE)>='20250901'  AND dc.IsValidCustomer=1
GROUP BY 
df.FTDPlatformName,
fc.FundingType, 
CAST(dc.FirstDepositDate AS DATE),
(DATEPART(WEEKDAY, CAST(dc.FirstDepositDate AS DATE)) + @@DATEFIRST - 1) % 7 + 1, 
CAST(DATEADD(WEEK, DATEDIFF(WEEK, -1, dc.FirstDepositDate), -1) AS DATE), 
frst.NewMarketingRegion, 
frst.Country