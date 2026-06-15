SELECT bddtrarl.DateID
	, bddtrarl.IsCreditReportValidCB
	, bddtrarl.Regulation
	, bddtrarl.PlayerLevel
	, SUM(bddtrarl.CryptoCommission) CryptoCommission
	, SUM(bddtrarl.CommoditiesCommission) CommoditiesCommission
	, SUM(bddtrarl.CurrenciesCommission) CurrenciesCommission
	, SUM(bddtrarl.IndicesCommission) IndicesCommission
	, SUM(bddtrarl.StocksAndETFsCommission) StocksAndETFsCommission
	, SUM(bddtrarl.CopyCommission) [CopyCommission (Other)]
	, SUM(bddtrarl.OvernightFee)  OvernightFee
	, SUM(bddtrarl.CashoutFee) CashoutFee
FROM BI_DB_DDR_TimeRange_Aggregated_Country_Level bddtrarl
WHERE bddtrarl.TimeRange = 'Yesterday'
AND bddtrarl.DateID BETWEEN 
CAST(CONVERT(VARCHAR(8), <[Parameters].[Parameter 1]>, 112) AS INT) 
AND 
CAST(CONVERT(VARCHAR(8), <[Parameters].[Parameter 2]>, 112) AS INT)
--AND bddtrarl.IsCreditReportValidCB = 1
--AND bddtrarl.PlayerLevel <> 'Internal'
GROUP BY bddtrarl.DateID
	, bddtrarl.IsCreditReportValidCB
	, bddtrarl.Regulation
	, bddtrarl.PlayerLevel