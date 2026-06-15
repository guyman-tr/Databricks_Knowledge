SELECT	[CID],
	[Active_Month],
	[ActiveDate],
	[Country],
	[Region],
	[EOM_Club]
	FROM [BI_DB].[dbo].[BI_DB_CID_MonthlyPanel_FullData]
	WHERE ActiveDate >= CONVERT(DATE, '2021-01-01')