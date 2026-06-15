SELECT bddcl.DateID, 
		bddcl.MifidCategory, 
		bddcl.Country, 
		bddcl.TimeRange, 
		bddcl.Regulation, 
		bddcl.IsCreditReportValidCB, 
		bddcl.PlayerLevel,
		sum(isnull([Revenue],0)) - 
		sum(isnull([DividendsPaid],0)) +
		sum(isnull([InterestFees],0)) +
		sum(isnull([ConversionFees],0)) +
		sum(isnull([DormantFee],0)) AS [Revenue_ex_Div]
FROM BI_DB..BI_DB_DDR_TimeRange_Aggregated_Country_Level bddcl WITH (NOLOCK)
WHERE 1=1
--AND TimeRange = 'Yesterday'
AND DateID = CAST(CONVERT(CHAR(8),<[Parameters].[Parameter 2]>, 112) AS INT)
GROUP BY bddcl.DateID, 
			bddcl.MifidCategory, 
			bddcl.Country,
			bddcl.TimeRange, 
			bddcl.Regulation, 
			bddcl.IsCreditReportValidCB,
			bddcl.PlayerLevel