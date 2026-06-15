SELECT bdim.CID
		,bdim.RegulationID
		,bdim.StatusID
		,bdim.MonthOfInterest
		,bdim.MonthlyAccumulatedInterest
		,bdim.TaxPercentage
		,bdim.FinalTaxedlnterest
		,bdim.ValidFrom
		,bdim.UpdateDate
		,co.Region
FROM dbo.BI_DB_InterestMonthly bdim
JOIN  [DWH].[dbo].[Dim_Customer] as dc
ON bdim.CID=dc.RealCID
JOIN [DWH].[dbo].[Dim_Country] co
ON dc.CountryID = co.CountryID
WHERE bdim.RegulationID=1