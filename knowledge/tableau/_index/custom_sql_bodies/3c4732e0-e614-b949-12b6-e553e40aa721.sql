SELECT CID,
		FullDate [Date],
		Liabilities+ActualNWA TotalEquity,
		ActualNWA NWA,
		TotalCash AvailableCash,
		WA_Liabilities CashEquity,
                BonusCredit
FROM DWH_dbo.V_Liabilities
WHERE CID=<[Parameters].[Parameter 1]> AND FullDate=<[Parameters].[Parameter 2]>