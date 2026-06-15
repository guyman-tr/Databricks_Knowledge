SELECT bdcd.CID
		,bdcd.Country
		,bdcd.State
		,dc.City
		,dc.Zip
		,bdcd.NewMarketingRegion
		,dc.PlayerLevelID
FROM BI_DB_dbo.BI_DB_CIDFirstDates bdcd
JOIN DWH_dbo.Dim_Customer dc
ON bdcd.CID = dc.RealCID
WHERE bdcd.IsFundedNew = 1
and IsValidCustomer = 1