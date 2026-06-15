SELECT dc.GCID
		,dc.RealCID
		,dc.RegisteredReal
		,dc.FirstDepositDate
		,dc.FirstDepositAmount
		,dc.IsValidCustomer
		,dc.VerificationLevelID
		,dc.[2FA]
		,dc1.Region
		,dc1.MarketingRegionManualName [MarketingRegion]
		,dc1.Name [Country]
		,dr.Name [Regulation]
		,dr1.Name [DesignatedRegulation]
		,dc2.Channel
		,dc2.SubChannel
		,dc2.[Organic/Paid]
FROM DWH..Dim_Customer dc
LEFT JOIN DWH..Dim_Country dc1 ON dc.CountryID = dc1.CountryID
LEFT JOIN DWH..Dim_Regulation dr ON dc.RegulationID = dr.DWHRegulationID
LEFT JOIN DWH..Dim_Regulation dr1 ON dc.DesignatedRegulationID = dr1.DWHRegulationID
LEFT JOIN DWH.dbo.Dim_Channel dc2 ON dc.SubChannelID = dc2.SubChannelID