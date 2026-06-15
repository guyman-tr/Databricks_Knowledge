SELECT dc1.Region, EOMONTH(fca.Occurred) AS EOMONTH, CAST(fca.Occurred AS DATE) AS OccurredDate
, COUNT(DISTINCT CASE WHEN CategoryID = 18 THEN fca.RealCID END) AS ActiveOpen
, COUNT(DISTINCT fca.PositionID) AS TotalTrades_OpenPlusClose
FROM [DWH_dbo].[Fact_CustomerAction] fca with (nolock)
JOIN [DWH_dbo].Dim_Customer dc ON fca.RealCID = dc.RealCID
JOIN [DWH_dbo].Dim_Country dc1 ON dc1.CountryID = dc.CountryID
JOIN [DWH_dbo].Dim_Instrument di ON di.InstrumentID = fca.InstrumentID
JOIN [DWH_dbo].Dim_ActionType dat ON fca.ActionTypeID = dat.ActionTypeID
WHERE dat.CategoryID IN (17,18) AND dc.IsValidCustomer = 1 AND fca.DateID >= 20240101
GROUP BY dc1.Region, EOMONTH(fca.Occurred), CAST(fca.Occurred AS DATE)