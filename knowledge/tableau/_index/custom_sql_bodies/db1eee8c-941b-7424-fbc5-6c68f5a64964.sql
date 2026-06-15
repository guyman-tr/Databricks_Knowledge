SELECT	dc.MarketingRegionManualName [MarketingRegion]
		,bdad.Region
		,bdad.[Country (customer)]
		,bdad.Year
		,bdad.Month
		,bdad.FundingType
		,bdad.PaymentStatus
		,COUNT(DISTINCT bdad.DepositID) [Deposits Count]
		,COUNT(DISTINCT bdad.CID) [CID_Count]
FROM BI_DB..BI_DB_AllDeposits bdad
LEFT JOIN DWH..Dim_Country dc ON bdad.[Country (customer)] = dc.Name
WHERE bdad.Year IN (2022)
GROUP BY dc.MarketingRegionManualName
		,bdad.Region
		,bdad.[Country (customer)]
		,bdad.Year
		,bdad.Month
		,bdad.FundingType
		,bdad.PaymentStatus