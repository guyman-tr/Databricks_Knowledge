SELECT DISTINCT [CID], [Active_Month], [ActiveDate], [IsFTD_ThisM], [FTD_Month], [FTDdate], [FTDA], [IsReg_ThisM], [RegMonth], [RegDate], [Region], [Country], [Channel], [SubChannel], [FirstAction], [FirstInstrument], [TotalDeposits], [CountDeposits], [NetDeposits], [TotalCashouts], [CashoutsAdjusted],
CASE WHEN [Country] IN ('Taiwan', 'Malaysia', 'Singapore', 'Philippines', 'Vietnam', 'Thailand', 'Indonesia', 'India', 'South Korea', 'Macau', 'Hong Kong') THEN [Country] ELSE 'ROW' END AS COUNTRY_Updated
FROM [BI_DB].[dbo].[BI_DB_CID_MonthlyPanel_FullData]
WHERE [Active_Month] >= 202101