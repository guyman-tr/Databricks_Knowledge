Select 
	EOMONTH(LastModificationDate) as Month
	,TargetPlatform
	,FiatCurrency
	,Sum(FiatAmount) as TotalFiatAmount
	,sum(UsdAmount) as usdamount
	,count(SentTransactionID) as totalTrx
FROM 
	EXW_dbo.EXW_C2F_E2E
WHERE 
	TargetPlatform = 'IbanAccount'
	and eMoneyLastTxStatus = 'Settled'
	and Year(LastModificationDate) >= '2025'
GROUP BY 
	EOMONTH(LastModificationDate)
	,TargetPlatform
	,FiatCurrency